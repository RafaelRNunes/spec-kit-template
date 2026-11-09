#!/usr/bin/env python3
"""Builds the metrics report of a branch from Claude Code transcripts and GitHub.

Usage: .claude/metrics.py [--save] [branch]
Without a branch, uses the current one. Prints Markdown, or with --save writes it to
docs/metrics/<branch>.md and prints the path. Needs no human input.

- Steps: a prompt that starts with a slash command opens a step; the prompts after it, until
  the next command, count as the same step (reviews, corrections, decisions).
- AI time: from each prompt to the last record of that turn, including waits for permission.
- Gaps: from the end of a turn to the next prompt on the same branch. They include review,
  pauses and nights, so they are an upper bound for human time, never an exact value.
- Tokens: every main and subagent record whose gitBranch is the branch, once per message.
- Pull request: read with `gh`, when available.
"""
import contextlib
import io
import json
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

FIELDS = (
    ("input_tokens", "input"),
    ("output_tokens", "output"),
    ("cache_creation_input_tokens", "cache write"),
    ("cache_read_input_tokens", "cache read"),
)
COMMAND = re.compile(r"(?:<command-name>|^)\s*(/[a-z][\w.:-]*)", re.MULTILINE)
NOT_PROMPT = ("<local-command", "<task-notification", "<system-reminder")


def run(*args):
    try:
        return subprocess.run(args, capture_output=True, text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def parse_time(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone()


def prompt_label(record):
    """Returns the step label of a human prompt, or None when the record is not one."""
    if record.get("type") != "user" or record.get("isMeta") or record.get("isSidechain"):
        return None
    content = (record.get("message") or {}).get("content")
    if isinstance(content, list):
        if any(block.get("type") != "text" for block in content if isinstance(block, dict)):
            return None
        content = " ".join(block.get("text", "") for block in content if isinstance(block, dict))
    if not isinstance(content, str) or content.lstrip().startswith(NOT_PROMPT):
        return None
    match = COMMAND.search(re.sub(r"</?pasted_content[^>]*>", "", content))
    return match.group(1) if match else ""


def load(folder):
    sessions = defaultdict(list)
    subagent_records = []
    for path in folder.rglob("*.jsonl"):
        is_subagent = "subagents" in path.parts
        for line in path.open(encoding="utf-8"):
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(record, dict) or not record.get("timestamp"):
                continue
            record["_at"] = parse_time(record["timestamp"])
            if is_subagent:
                subagent_records.append(record)
            else:
                sessions[path.stem].append(record)
    return sessions, subagent_records


def build_turns(sessions, branch):
    turns = []
    for records in sessions.values():
        records.sort(key=lambda r: r["_at"])
        current = None
        for record in records:
            label = prompt_label(record)
            if label is not None:
                current = {"label": label, "start": record["_at"], "end": record["_at"], "branches": set()}
                turns.append(current)
            elif current and record.get("type") in ("assistant", "user", "system"):
                current["end"] = max(current["end"], record["_at"])
            if current and record.get("gitBranch"):
                current["branches"].add(record["gitBranch"])
    turns = [t for t in turns if branch in t["branches"]]
    turns.sort(key=lambda t: t["start"])
    step = "conversation before the first command"
    for turn in turns:
        step = turn["label"] = turn["label"] or step
    for turn, following in zip(turns, turns[1:] + [None]):
        turn["gap"] = (following["start"] - turn["end"]).total_seconds() if following else 0
    return turns


def usage_records(sessions, subagent_records, branch):
    """One entry per message: (time, model, usage)."""
    messages = {}
    for record in [r for rs in sessions.values() for r in rs] + subagent_records:
        message = record.get("message")
        if record.get("gitBranch") != branch or not isinstance(message, dict):
            continue
        model, usage = message.get("model"), message.get("usage")
        if not usage or not model or model == "<synthetic>":
            continue
        messages[message.get("id") or record.get("uuid")] = (record["_at"], model, usage)
    return list(messages.values())


def sum_tokens(entries):
    totals = defaultdict(lambda: defaultdict(int))
    for _, model, usage in entries:
        for field, _ in FIELDS:
            totals[model][field] += usage.get(field) or 0
    return totals


def tokens_text(totals):
    if not totals:
        return "not measured"
    return "; ".join(
        f"{model}: " + ", ".join(f"{label} {values[field]}" for field, label in FIELDS)
        for model, values in sorted(totals.items())
    )


def duration(seconds):
    seconds = int(seconds)
    hours, rest = divmod(seconds, 3600)
    minutes, secs = divmod(rest, 60)
    if hours:
        return f"{hours} h {minutes} min"
    if minutes:
        return f"{minutes} min {secs} s"
    return f"{secs} s"


def pull_request(branch):
    raw = run("gh", "pr", "list", "--head", branch, "--state", "all", "--limit", "1",
              "--json", "number,url,createdAt,mergedAt,reviews")
    try:
        items = json.loads(raw)
    except json.JSONDecodeError:
        return None
    return items[0] if items else None


def main():
    root = run("git", "rev-parse", "--show-toplevel")
    if not root:
        sys.exit("Error: run inside the project repository.")
    args = sys.argv[1:]
    save = "--save" in args
    args = [a for a in args if a != "--save"]
    branch = args[0] if args else run("git", "branch", "--show-current")
    if save:
        buffer = io.StringIO()
        with contextlib.redirect_stdout(buffer):
            report(root, branch)
        path = Path(root) / "docs" / "metrics" / (branch.replace("/", "-") + ".md")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(buffer.getvalue(), encoding="utf-8")
        print(path.relative_to(root))
    else:
        report(root, branch)


def report(root, branch):
    folder = Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", root)

    sessions, subagent_records = load(folder)
    turns = build_turns(sessions, branch)
    entries = usage_records(sessions, subagent_records, branch)
    if not turns:
        sys.exit(f"Error: no Claude Code records on branch {branch}.")

    pr = pull_request(branch)
    start = turns[0]["start"]
    merged = parse_time(pr["mergedAt"]) if pr and pr.get("mergedAt") else None
    end = max(merged or turns[-1]["end"], turns[-1]["end"])
    ai_time = sum((t["end"] - t["start"]).total_seconds() for t in turns)
    gaps = [t["gap"] for t in turns[:-1]]

    fmt = "%Y-%m-%d %H:%M:%S"
    print(f"# Metrics: {branch}\n")
    print(f"Generated on {datetime.now().strftime(fmt)} by `.claude/metrics.py` from Claude Code transcripts "
          "and GitHub. Gaps include review, breaks and nights: they are an upper bound for human time, "
          "never the exact value.\n")
    print("## Summary\n")
    print("| Item | Value |\n|---|---|")
    print(f"| First prompt | {start.strftime(fmt)} |")
    print(f"| End | {end.strftime(fmt)} ({'last record, after the merge' if merged and end > merged else 'PR merge' if merged else 'last record; not merged'}) |")
    print(f"| Wall-clock time | {duration((end - start).total_seconds())} |")
    print(f"| AI time | {duration(ai_time)} in {len(turns)} turns |")
    print(f"| Gaps between turns | {duration(sum(gaps))} in total; longest {duration(max(gaps, default=0))} |")
    if pr:
        created = parse_time(pr["createdAt"])
        review = duration((merged - created).total_seconds()) if merged else "not merged"
        print(f"| PR | [#{pr['number']}]({pr['url']}): open to merge, {review}; "
              f"{len(pr.get('reviews') or [])} GitHub reviews |")
    else:
        print("| PR | not found or `gh` unavailable |")

    print("\n## By step\n")
    print("| Step | Turns | AI time | Gap after | Tokens by model |\n|---|---|---|---|---|")
    steps = {}
    for turn in turns:
        step = steps.setdefault(turn["label"], {"turns": 0, "ai": 0, "gap": 0, "entries": []})
        step["turns"] += 1
        step["ai"] += (turn["end"] - turn["start"]).total_seconds()
        step["gap"] += turn["gap"]
        step["entries"] += [e for e in entries if turn["start"] <= e[0] <= turn["end"]]
    for label, step in steps.items():
        print(f"| `{label}` | {step['turns']} | {duration(step['ai'])} | {duration(step['gap'])} | "
              f"{tokens_text(sum_tokens(step['entries']))} |")

    print("\n## Tokens by model on the branch\n")
    print("| Model | " + " | ".join(label.capitalize() for _, label in FIELDS) + " |")
    print("|---|" + "---|" * len(FIELDS))
    for model, values in sorted(sum_tokens(entries).items()):
        print(f"| {model} | " + " | ".join(str(values[field]) for field, _ in FIELDS) + " |")


if __name__ == "__main__":
    main()
