"""V4.76 integration: disposable data and mocked screenshot transport, not live Wayland."""
import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path
import os
import unittest
from unittest.mock import patch
ROOT = Path(__file__).resolve().parents[1]
def load(name):
    loader = SourceFileLoader('v476_' + name.replace('-', '_'), str(ROOT / 'bin' / name))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
    loader.exec_module(module)
    return module
class Integration(unittest.TestCase):
    def test_legacy_date_survives_clean_layout(self):
        bar = load('rice-bar')
        layout = {'left': ['date'], 'center': ['music'], 'right': ['tray']}
        self.assertEqual({k: bar.clean_layout(layout)[k] for k in layout}, layout)
        self.assertFalse(bar.DEFAULTS['island_date'])
        self.assertTrue(bar.DEFAULTS['island_ai'])
        self.assertIn('case "date": return mDate', (ROOT/'quickshell/rice-desktop/Bar.qml').read_text())
    def test_explicit_remove_and_restore_island(self):
        bar = load('rice-bar')
        c = {'layout': {'left': ['date'], 'center': ['music'], 'right': []}}
        bar.island_flag(c); self.assertTrue(c['island_off'])
        c['layout']['center'].append('island')
        bar.island_flag(c); self.assertFalse(c['island_off'])
    def test_german_quoted_keyboard_values(self):
        hypr = load('hypr-set')
        for raw in ['de', '"de"', "'de'", '  "de"  ']:
            self.assertEqual(hypr.kbd_clean(raw), 'de')
    def test_niri_window_capture_falls_back_to_region(self):
        shot = load('rice-hotcorner')
        with patch.dict(os.environ, {'NIRI_SOCKET': '/mock', 'RICE_SNIP_OFF': ''}), patch.object(shot, 'snip', return_value=True) as snip:
            shot.shot_take('window')
            snip.assert_called_once_with('region')
    def test_hypr_window_capture_keeps_window_mode(self):
        shot = load('rice-hotcorner')
        with patch.dict(os.environ, {'RICE_SNIP_OFF': ''}), patch.object(shot, 'snip', return_value=True) as snip:
            os.environ.pop('NIRI_SOCKET', None)
            shot.shot_take('window')
            snip.assert_called_once_with('window')
