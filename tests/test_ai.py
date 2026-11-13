"""Agent activity regressions use synthetic session logs, never real conversations."""
from importlib.machinery import SourceFileLoader
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = SourceFileLoader("rice_ai", str(ROOT / "bin/rice-ai"))
spec = importlib.util.spec_from_loader(loader.name, loader)
ai = importlib.util.module_from_spec(spec)
loader.exec_module(ai)


class AgentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.env = patch.dict(os.environ, {"CODEX_HOME": str(self.home / ".codex"),
                                          "CLAUDE_CONFIG_DIR": str(self.home / ".claude"),
                                          "XDG_CACHE_HOME": str(self.home / ".cache")})
        self.env.start()
        self.addCleanup(self.env.stop)
        self.monitor = ai.Monitor(self.home)
        self.now = time.time()
        self.stamp = ai.dt.datetime.fromtimestamp(self.now, ai.dt.timezone.utc).isoformat()

    def write(self, path, *records):
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a") as stream:
            for record in records:
                stream.write(json.dumps(dict(timestamp=self.stamp, **record)) + "\n")
        return path

    def codex(self, name="one"):
        return self.home / ".codex/sessions/2026/11/13" / ("rollout-" + name + ".jsonl")

    def event(self, kind, **fields):
        return dict(type="event_msg", payload=dict(type=kind, **fields))

    def test_codex_desktop_lifecycle_usage_and_no_prompt_output(self):
        path = self.write(self.codex(),
            dict(type="session_meta", payload=dict(cwd="/work/app", originator="Codex Desktop", base_instructions="SECRET")),
            dict(type="turn_context", payload=dict(model="test-model")), self.event("task_started"),
            self.event("token_count", info=dict(total_token_usage=dict(input_tokens=1200, output_tokens=80, cached_input_tokens=900),
                last_token_usage=dict(total_tokens=500), model_context_window=1000),
                rate_limits=dict(primary=dict(used_percent=25, window_minutes=300, resets_at=12345))))
        snapshot = self.monitor.snapshot(self.now)
        d = snapshot["providers"][0]
        self.assertEqual((d["state"], d["source"], d["project"], d["input"], d["context"]),
                         ("working", "Desktop", "app", 1200, .5))
        self.assertEqual(d["limits"][0]["used"], 25)
        self.assertNotIn("SECRET", json.dumps(snapshot))
        self.write(path, self.event("task_complete"))
        self.assertEqual(self.monitor.snapshot(self.now)["active"], 0)
        self.write(path, self.event("task_started"), self.event("turn_aborted"))
        self.assertEqual(self.monitor.snapshot(self.now)["active"], 0)

    def test_multiple_sessions_do_not_hide_work_when_another_finishes(self):
        self.write(self.codex("one"), self.event("task_started"))
        two = self.write(self.codex("two"), self.event("task_started"))
        self.assertEqual(self.monitor.snapshot(self.now)["active"], 2)
        self.write(two, self.event("task_complete"))
        d = self.monitor.snapshot(self.now)["providers"][0]
        self.assertEqual((d["active"], d["state"]), (1, "working"))

    def test_live_card_tracks_parallel_tools_and_resets_each_turn(self):
        path = self.write(self.codex(), self.event("task_started"),
            dict(type="response_item", payload=dict(type="custom_tool_call", call_id="edit", name="functions.exec",
                input='await tools.apply_patch("SECRET FILE CONTENT")')),
            dict(type="response_item", payload=dict(type="function_call", call_id="search", name="web.search")))
        d = self.monitor.snapshot(self.now)["providers"][0]
        self.assertEqual((d["action"], d["tools"]), ("searching", 2))
        self.assertNotIn("SECRET", json.dumps(d))
        self.write(path, dict(type="response_item", payload=dict(type="function_call_output", call_id="search")))
        self.assertEqual(self.monitor.snapshot(self.now)["providers"][0]["action"], "editing")
        self.write(path, dict(type="response_item", payload=dict(type="custom_tool_call_output", call_id="edit")))
        self.assertEqual(self.monitor.snapshot(self.now)["providers"][0]["action"], "thinking")
        self.write(path, self.event("task_complete"), self.event("task_started"))
        self.assertEqual(self.monitor.snapshot(self.now)["providers"][0]["tools"], 0)

    def test_claude_live_tool_chunks_do_not_inflate_the_call_count(self):
        path = self.home / ".claude/projects/test/session.jsonl"
        message = dict(id="msg-1", content=[dict(type="tool_use", id="tool-1", name="Edit", input={"content": "SECRET"})])
        self.write(path, dict(type="user", message={}), dict(type="assistant", message=message), dict(type="assistant", message=message))
        d = self.monitor.snapshot(self.now)["providers"][1]
        self.assertEqual((d["action"], d["tools"]), ("editing", 1))
        self.write(path, dict(type="user", message=dict(content=[dict(type="tool_result", tool_use_id="tool-1")])) )
        self.assertEqual(self.monitor.snapshot(self.now)["providers"][1]["action"], "thinking")

    def test_partial_writes_rotation_and_stale_sessions(self):
        path = self.write(self.codex(), self.event("task_started"))
        self.assertEqual(self.monitor.snapshot(self.now)["active"], 1)
        with path.open("a") as stream:
            stream.write(json.dumps(self.event("task_complete")))
        self.assertEqual(self.monitor.snapshot(self.now)["active"], 1)
        with path.open("a") as stream:
            stream.write("\n")
        self.assertEqual(self.monitor.snapshot(self.now)["active"], 0)
        path.write_text("")
        self.write(path, self.event("task_started"))
        d = self.monitor.snapshot(self.now + ai.STALE + 1)["providers"][0]
        self.assertEqual((d["active"], d["state"]), (0, "unknown"))

    def test_claude_streamed_usage_is_deduplicated_and_subagents_excluded(self):
        path = self.home / ".claude/projects/test/session.jsonl"
        usage = dict(input_tokens=10, output_tokens=5, cache_read_input_tokens=20, cache_creation_input_tokens=30)
        message = dict(id="msg-1", model="claude-test", usage=usage, stop_reason=None)
        self.write(path, dict(type="user", cwd="/work/claude-app", message={"content": "SECRET"}),
                   dict(type="assistant", message=message), dict(type="assistant", message=message),
                   dict(type="assistant", message=dict(message, stop_reason="end_turn")))
        self.write(path.parent / "session/subagents/agent-1.jsonl", dict(type="user", message={}))
        d = self.monitor.snapshot(self.now)["providers"][1]
        self.assertEqual((d["input"], d["output"], d["cached"], d["state"]), (60, 5, 20, "idle"))
        self.assertIsNone(d["context"])
        self.assertEqual(len(self.monitor.sessions), 1)

    def send_hook(self, event):
        with patch.object(ai.sys, "stdin", io.StringIO(json.dumps(dict(hook_event_name=event, session_id="session", cwd="/work/app")))):
            ai.hook_claude()

    def test_permission_hook_and_stop_override_transcript_without_losing_usage(self):
        self.write(self.home / ".claude/projects/test/session.jsonl", dict(type="assistant", message=dict(
            id="msg", model="claude-test", usage=dict(input_tokens=12, output_tokens=3), stop_reason=None)))
        self.send_hook("PermissionRequest")
        d = self.monitor.snapshot()["providers"][1]
        self.assertEqual((d["state"], d["input"], d["active"]), ("waiting", 12, 1))
        self.send_hook("Stop")
        self.assertEqual(self.monitor.snapshot()["providers"][1]["state"], "idle")
        cached = next(self.monitor.cache.glob("*.json"))
        self.assertEqual(cached.stat().st_mode & 0o777, 0o600)
        self.assertNotIn("message", cached.read_text())

    def test_hook_install_preserves_settings_and_is_idempotent(self):
        path = self.home / ".claude/settings.json"
        path.parent.mkdir(parents=True)
        original = dict(model="existing", hooks={"Stop": [{"hooks": [{"type": "command", "command": "existing-helper"}]}]})
        path.write_text(json.dumps(original))
        with patch.object(ai.sys, "stdout", io.StringIO()):
            ai.install_hooks()
            first = path.read_text()
            ai.install_hooks()
        self.assertEqual(path.read_text(), first)
        settings = json.loads(first)
        self.assertEqual(settings["model"], "existing")
        self.assertEqual(settings["hooks"]["Stop"][0], original["hooks"]["Stop"][0])
        self.assertEqual(len(list(path.parent.glob("settings.json.before-rice-ai-*"))), 1)

    def test_malformed_records_and_no_sessions_are_harmless(self):
        self.assertEqual(self.monitor.snapshot()["active"], 0)
        path = self.codex()
        path.parent.mkdir(parents=True)
        path.write_text("invalid json\n[]\n{}\n")
        self.monitor.scanned = 0
        self.assertEqual(self.monitor.snapshot()["active"], 0)


if __name__ == "__main__":
    unittest.main()
