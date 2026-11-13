import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("sync_scale", Path(__file__).parents[1] / "sync-scale.py")
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class ScaleSyncTest(unittest.TestCase):
    def test_only_valid_enabled_monitor_scales_are_exported(self):
        with tempfile.TemporaryDirectory() as directory:
            settings = Path(directory) / "hypr.json"
            settings.write_text(json.dumps({"monitors": {
                "eDP-2": {"scale": 1.6, "mode": "2560x1600@240"},
                "DP-1": {"scale": 1.25},
                "DP-2": {"scale": 2, "disabled": True},
                "bad\nsetting": {"scale": 2},
                "HDMI-1": {"scale": True},
                "HDMI-2": {"scale": "1.5"},
                "HDMI-3": {"scale": 999},
                "HDMI-4": {"scale": float("nan")},
                "HDMI-5": None,
            }, "private-setting": "must not be exported"}))
            self.assertEqual(sync.read_scales(settings), {"eDP-2": 1.6, "DP-1": 1.25})

    def test_next_start_uses_updated_settings_and_package(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "package-one"
            source.mkdir()
            (source / "Main.qml").write_text("first package")
            settings = root / "hypr.json"
            settings.write_text('{"monitors":{"eDP-2":{"scale":1.6}}}')
            target = root / "runtime/theme"
            sync.prepare_theme(settings, source, target)
            config = (target / "theme.conf.user").read_text().split("monitorScales=", 1)[1].strip()
            self.assertEqual(json.loads(json.loads(config)), {"eDP-2": 1.6})
            newer = root / "package-two"
            newer.mkdir()
            (newer / "Main.qml").write_text("new package")
            settings.write_text('{"monitors":{"eDP-2":{"scale":1.25}}}')
            sync.prepare_theme(settings, newer, target)
            self.assertEqual((target / "Main.qml").read_text(), "new package")
            config = (target / "theme.conf.user").read_text().split("monitorScales=", 1)[1].strip()
            self.assertEqual(json.loads(json.loads(config)), {"eDP-2": 1.25})

    def test_bad_or_missing_settings_do_not_block_login(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "hypr.json"
            self.assertEqual(sync.read_scales(path), {})
            for contents in ("broken json", "null", '[]', '{"monitors":[]}'):
                path.write_text(contents)
                self.assertEqual(sync.read_scales(path), {})


if __name__ == "__main__":
    unittest.main()
