"""The frozen compositor PNG is the pixel authority, independent of Qt DPR."""
import binascii
import importlib.util
from importlib.machinery import SourceFileLoader
import os
from pathlib import Path
import shutil
import struct
import tempfile
import unittest
from unittest.mock import patch
import zlib

ROOT = Path(__file__).resolve().parents[1]
LOADER = SourceFileLoader("snip_hotcorner", str(ROOT / "bin/rice-hotcorner"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
SNIP = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(SNIP)


def pattern_png(path, w, h):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", binascii.crc32(kind + data))

    raw = b"".join(b"\x00" + b"".join(bytes((x % 256, y % 256, 23)) for x in range(w)) for y in range(h))
    data = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
    path.write_bytes(data)
    return data


class SnipPixels(unittest.TestCase):
    def test_scale_1_6_uses_real_output_pixels_once(self):
        self.assertEqual(SNIP.snip_box((1280, 800), (800, 500), (210, 190, 100, 100)),
                         (336, 304, 160, 160))

    def test_round_shared_edges_and_clip(self):
        native, view = (1001, 748), (667, 499)
        a = SNIP.snip_box(native, view, (-10, -3, 110.5, 53.5))
        b = SNIP.snip_box(native, view, (100.5, 50.5, 1000, 1000))
        self.assertEqual(a, (0, 0, 151, 76))
        self.assertEqual((a[0] + a[2], a[1] + a[3]), b[:2])
        self.assertEqual((b[0] + b[2], b[1] + b[3]), native)
        self.assertEqual(SNIP.snip_box(native, view, (667, 499, 0, 0), color=True), (1000, 747, 1, 1))
        with self.assertRaises(ValueError):
            SNIP.snip_box(native, view, (668, 500, 1, 1))
        with self.assertRaises(ValueError):
            SNIP.snip_box(native, view, (float("nan"), 2, 4, 5))

    def test_full_capture_retains_identical_bytes_without_encoder(self):
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {"XDG_RUNTIME_DIR": tmp}):
            p = Path(tmp) / "rice-snip-123.png"
            native = pattern_png(p, 80, 48)
            def complete(path, action):
                self.assertEqual(action, "save")
                self.assertEqual(Path(path).read_bytes(), native)
            with patch.object(SNIP, "shot_done", side_effect=complete) as done, patch.object(SNIP.shutil, "which", return_value=None):
                self.assertTrue(SNIP.shot_crop(str(p), "save", ["0", "0", "50", "30", "50", "30"]))
                done.assert_called_once()
            self.assertFalse(p.exists())

    @unittest.skipUnless(shutil.which("magick") or shutil.which("convert"), "ImageMagick unavailable")
    def test_crop_and_color_use_exact_source_pixels(self):
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {"XDG_RUNTIME_DIR": tmp}):
            p = Path(tmp) / "rice-snip-123.png"
            for action, xywh, expected_shape in (("copy", ["10", "15", "10", "12"], (16, 19)),
                                                ("color", ["10", "15", "0", "0"], (1, 1))):
                pattern_png(p, 128, 80)
                def complete(path, result_action):
                    self.assertEqual(result_action, action)
                    self.assertEqual(SNIP.png_size(path), expected_shape)
                    self.assertEqual(SNIP.png_pixel(path), (16, 24, 23))
                with patch.object(SNIP, "shot_done", side_effect=complete) as done:
                    self.assertTrue(SNIP.shot_crop(str(p), action, [*xywh, "80", "50"]))
                    done.assert_called_once()
                self.assertFalse(p.exists())

    def test_gui_sends_monitor_local_geometry_and_leaves_recording_global(self):
        qml = (ROOT / "quickshell/rice-desktop/Snip.qml").read_text()
        self.assertIn('String(x), String(y), String(w), String(h), String(width), String(height)', qml)
        self.assertIn('x: c.at[0] - m.x, y: c.at[1] - m.y', qml)
        self.assertIn('Math.round(ox + sx)', qml)
        self.assertNotIn('grabToImage(', qml)
