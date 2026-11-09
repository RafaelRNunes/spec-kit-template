---
name: speckit-feature-branch
description: "Before /speckit-specify and /speckit-bug-fix: updates main, saves the metrics of the merged branch and creates the branch. Runs as the before_specify and before_bug_fix hook."
argument-hint: "Feature description (the text passed to /speckit-specify) or the bug slug"
user-invocable: true
disable-model-invocation: false
---

## Input

```text
$ARGUMENTS
```

## Steps

1. Run `git status --porcelain`. If there are changes, STOP: list the files and ask whether to commit, stash or discard them. Never stash or discard on your own. Exception: in `/speckit-bug-fix`, new files in `.specify/bugs/<BUG_SLUG>/` are the bug assessment and move to the new branch.
2. Remember the current branch. If it is not `main`, check whether it has a merged PR (`gh pr list --head <branch> --state merged`). If not, and it has commits outside `origin/main`, STOP and ask before leaving it.
3. Run `git checkout main && git pull --ff-only`. If the pull fails, STOP and report.
4. Pick the branch:
   - `/speckit-specify`: `feature/<short-name>`, 2 to 4 kebab-case words from the description.
   - `/speckit-bug-fix`: `fix/<BUG_SLUG>`.
5. Run `git checkout -b <branch>`. If it already exists, STOP and ask.
6. If the branch from step 2 was merged and `docs/metrics/<branch with / replaced by ->.md` does not exist, run `.claude/metrics.py --save <branch>`. The file goes into the first commit of the new branch. If the command fails, report and continue.
7. Return the JSON below and continue with the command that called the hook:

   ```json
   {"BRANCH_NAME": "<branch>"}
   ```
