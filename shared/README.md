# Shared work

[messages.jsonl](messages.jsonl) is the shared mailbox on `main`. Each line is one JSON message with a unique ID, an ISO 8601 UTC timestamp ending in `Z`, sender, recipient, kind, optional parent IDs and text. Read in file order. Reply to corrections with a new entry so both sides retain the history.

**Roles.** Dean’s interactive Codex edits the server and makes releases. Jake’s assistant gathers client evidence, helps design tests and reports results. The timer on each PC can draft a text reply from the mailbox. It runs a separate short-lived Codex CLI session. Screenshots, live chat history and player actions must come from the interactive session.

## One-time Windows setup

Each participant needs Git, GitHub CLI, Python 3.10 or later, and a current Codex CLI signed in on their own Windows account. Use `gh auth login` and `codex login` if needed. Clone the private repo with `gh repo clone dvaknin001/pjd-testing`, or run `git pull --ff-only` in an existing clean checkout. From the repo root run the applicable command:

~~~powershell
# Jake
powershell -NoProfile -File .\shared\install.ps1 -Role helper
# Dean
powershell -NoProfile -File .\shared\install.ps1 -Role lead
~~~

The installer copies the reviewed relay into `%LOCALAPPDATA%\PJD-Relay\<role>` and registers a five-minute Windows task under the signed-in user. It works while that PC is awake and the user is signed in. It catches up from GitHub when the PC returns. Re-run the installer after reviewing script updates. Use `Get-ScheduledTaskInfo -TaskName 'PJD mailbox - helper'` to check the timer, or `Disable-ScheduledTask -TaskName 'PJD mailbox - helper'` to pause it. Substitute `lead` on Dean’s PC.

## Read and send

~~~powershell
python shared/relay.py lead read
python shared/relay.py lead send --kind request --text "Please measure kills over ten minutes in the east camp."
python shared/relay.py helper send --kind report --text "Build …, character …, observed …, still untested …"
~~~

`request` and `report` can wake the recipient’s background assistant. `note` and `reply` are delivered silently. For a manual reply, use `--kind reply --reply-to FULL_MESSAGE_ID`. AI-generated replies are terminal, so acknowledgements cannot wake each other. One run processes up to four new messages together. Each PC reserves at most four model calls per UTC day, including failed attempts. Pending work carries over. Idle polls use only GitHub and Python. Check `health.json`, `inbox.json` and the daily count in `state.json` under the local relay folder.

## Synchronization

The send command reads the latest remote file, appends one entry and commits through GitHub using that exact file revision. On a concurrent edit it refetches and retries, then verifies its message on `main`. It does not touch staged or uncommitted files. Use it for mailbox writes, including end-of-work updates.

For other edits use a clean checkout, `git pull --ff-only` before starting, commit intended paths, fetch and rebase your local commits onto `origin/main` before pushing, then check the remote. If a push races, fetch and reconcile again. Keep game administration, credentials, binaries and private logs on the appropriate PC.
