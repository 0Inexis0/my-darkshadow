# Codex / Claude in the Dynamic Island

The **AI** tab next to System shows local Codex and Claude Code sessions, their
activity, model, project and session input/output tokens. Cached input is included
in the input total. Values refer to the displayed session, not a daily bill.
While an agent works, the clock pill shows its name and an animated equalizer.
Hover opens a separate live card with an animated agent badge, current activity,
project, elapsed time and tool-call count. It shows no token counts or quota limits.
The card follows tool start/end signals and shows completion if work finishes while
you hover. Click opens the AI usage tab; Music remains available in its own tab.
Volume, workspaces and recording keep their existing priority.

Settings → Dynamic island → **Codex / Claude** controls the compact activity
display. The AI tab can also be chosen as the default click target, or opened with:

```sh
rice-dashboard island ai
rice-bar set island_ai off
```

`bin/rice-ai` is installed with the other shell helpers. It uses Python's standard
library and makes no network requests. One process follows appended local JSONL
records for all screens. It reads `$CODEX_HOME/sessions` (default `~/.codex/sessions`)
and `$CLAUDE_CONFIG_DIR/projects` (default `~/.claude/projects`). Discovery is limited
to the 32 most recently modified sessions per provider from the last seven days.
Older records are read once at startup, then only complete appended lines are read.
Conversation text, tool arguments and credentials are never emitted or cached.

Codex's task start/complete/abort events drive the activity state for Desktop and
CLI sessions. Token-count records provide usage, context size and reported account
limits. Account limits are shown only when Codex reports them. No account calls,
estimated costs or invented percentages are used.

Claude Code transcripts provide activity and deduplicated message usage. For
explicit permission-waiting and session-end signals, install the optional hooks:

```sh
~/.local/bin/rice-ai install-claude-hooks
```

This merges commands into `~/.claude/settings.json`, preserves existing hooks and
settings, and backs up an existing file before changes. Re-running is idempotent.
Review/enable hooks in Claude if it requests that; restart older Claude versions
that do not reload hook settings. The hooks use only lifecycle metadata and write
private, atomic state files under `$XDG_CACHE_HOME/rice/ai`. They never request or
deny permissions and never return instructions to the agent. To remove them,
remove only the `rice-ai hook claude` entries in Claude's hook settings.
See the [official Claude hook reference](https://code.claude.com/docs/en/hooks).

Support covers **local Claude Code sessions**, including the Desktop Code view
when its session files/hooks run on this machine. Ordinary Claude Desktop chat,
browser conversations and remote/cloud sessions do not expose this local coding
lifecycle and are not inferred from an open app or CPU usage. Claude Code does
not expose account quota percentages in these transcripts, so its card shows
tokens and activity instead. A busy session with no new signal for 15 minutes is
marked “No recent signal” rather than staying active indefinitely after a crash.

Verification:

```sh
python3 -m unittest discover -s tests -p 'test_ai.py' -v
bin/rice-ai status
```

The regression suite uses synthetic logs for concurrent sessions, completion,
interrupts, partial writes, truncation, stale sessions, streaming usage,
permission hooks and preservation of existing settings.
