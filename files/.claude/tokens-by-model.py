#!/usr/bin/env python3
"""Sums tokens by model from this project's local transcripts, within a time range.

Usage: .claude/tokens-by-model.py "YYYY-MM-DD HH:MM:SS" "YYYY-MM-DD HH:MM:SS"
Times use the local timezone, like the `date` command. Subagent transcripts are included.
Each message counts once, because a response can span several transcript lines.
"""
import json
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

FIELDS = {
    "entrada": "input_tokens",
    "saída": "output_tokens",
    "cache escrito": "cache_creation_input_tokens",
    "cache lido": "cache_read_input_tokens",
}


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    start, end = (datetime.fromisoformat(a).astimezone() for a in sys.argv[1:])

    root = str(Path(__file__).resolve().parent.parent)
    folder = Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", root)

    messages = {}
    for path in folder.rglob("*.jsonl"):
        for line in path.open(encoding="utf-8"):
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(record, dict) or not record.get("timestamp"):
                continue
            message = record.get("message")
            if not isinstance(message, dict) or not message.get("usage"):
                continue
            model = message.get("model")
            if not model or model == "<synthetic>":
                continue
            when = datetime.fromisoformat(record["timestamp"].replace("Z", "+00:00"))
            if start <= when <= end:
                messages[message.get("id") or record.get("uuid")] = (model, message["usage"])

    if not messages:
        print("não medido")
        return

    totals = defaultdict(lambda: defaultdict(int))
    for model, usage in messages.values():
        for label, field in FIELDS.items():
            totals[model][label] += usage.get(field) or 0

    print("; ".join(
        f"{model}: " + ", ".join(f"{label} {values[label]}" for label in FIELDS)
        for model, values in sorted(totals.items())
    ))


if __name__ == "__main__":
    main()
