import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, MagicMock

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('vpn_controller', ROOT / 'nix/vpn/launcher.py')
vpn = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vpn)


class VpnStateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.runtime = Path(self.tmp.name) / 'runtime'
        self.prefs = Path(self.tmp.name) / 'prefs.json'
        self.runtime_patch = patch.object(vpn, 'RUNTIME', self.runtime)
        self.prefs_patch = patch.object(vpn, 'PREFS', self.prefs)
        self.runtime_patch.start()
        self.prefs_patch.start()
        self.addCleanup(self.runtime_patch.stop)
        self.addCleanup(self.prefs_patch.stop)

    def test_stale_worker_cannot_report_connected(self):
        vpn.save(vpn.runtime() / 'state.json', {'status': 'connected', 'pid': 999999999, 'ip': '192.0.2.1'})
        self.assertEqual(vpn.state()['status'], 'disconnected')
        self.assertNotIn('ip', vpn.state())

    def test_stop_never_signals_an_unmanaged_process(self):
        vpn.save(vpn.runtime() / 'state.json', {'status': 'connected', 'pid': 1})
        with patch.object(vpn.os, 'kill') as kill:
            vpn.disconnect()
        kill.assert_not_called()

    def test_unavailable_selected_city_does_not_silently_change_location(self):
        vpn.save(self.prefs, {'location': 'Seattle'})
        with patch.object(vpn, 'gateways', return_value=[{'location': 'Miami'}]), patch.object(vpn, 'fetch') as fetch:
            with self.assertRaisesRegex(RuntimeError, 'unavailable'):
                vpn.prepare()
        fetch.assert_not_called()

    def test_wrong_exit_country_disconnects_and_reports_failure(self):
        process = MagicMock()
        process.stdout = io.StringIO('USA_VPN_READY\n')
        with patch.object(vpn, 'prepare', return_value=[{'location': 'Miami'}]), \
             patch.object(vpn.subprocess, 'Popen', return_value=process), \
             patch.object(vpn, 'exit_country', return_value=('FR', '192.0.2.1')), \
             patch.object(vpn, 'stop_tunnel') as cleanup:
            vpn.worker()
        value = json.loads((self.runtime / 'state.json').read_text())
        self.assertEqual(value['status'], 'error')
        self.assertIn('not in the United States', value['message'])
        cleanup.assert_called_with(process)

    def test_duplicate_connect_does_not_start_another_worker(self):
        with patch.object(vpn, 'state', return_value={'status': 'connecting', 'pid': 123}), \
             patch.object(vpn.subprocess, 'Popen') as popen:
            self.assertEqual(vpn.start()['pid'], 123)
        popen.assert_not_called()

    def test_keepalive_summary_is_not_a_reconnect_event(self):
        process = MagicMock()
        process.stdout = io.StringIO('USA_VPN_READY\nTimers: ping 10, ping-restart 30\n')
        statuses = []
        actual_save = vpn.save
        def record(path, value):
            statuses.append(value.get('status'))
            actual_save(path, value)
        with patch.object(vpn, 'prepare', return_value=[{'location': 'Miami'}]), \
             patch.object(vpn.subprocess, 'Popen', return_value=process), \
             patch.object(vpn, 'exit_country', return_value=('US', '192.0.2.1')), \
             patch.object(vpn, 'save', side_effect=record), \
             patch.object(vpn, 'stop_tunnel'):
            vpn.worker()
        self.assertIn('connected', statuses)
        self.assertNotIn('connecting', statuses[statuses.index('connected') + 1:])


class RootInputTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = (ROOT / 'nix/vpn/root.py').read_text().replace('@CA@', repr('test CA'))
        cls.ns = {'__name__': 'vpn_root_test'}
        exec(compile(source, 'root.py', 'exec'), cls.ns)

    def test_remote_configuration_cannot_inject_commands(self):
        key_kind = 'PRIVATE KEY'
        valid = {'host': 'vpn22-mia.riseup.net', 'ip': '192.0.2.1', 'port': 1194, 'protocol': 'tcp-client',
                 'cert': '-----BEGIN CERTIFICATE-----\nYWJj\n-----END CERTIFICATE-----',
                 'key': f'-----BEGIN {key_kind}-----\nYWJj\n-----END {key_kind}-----'}
        self.assertIn('remote-cert-tls server', self.ns['config'](valid))
        for field, value in [('host', 'evil.example'), ('ip', '192.0.2.1\nup /tmp/evil'),
                             ('cert', valid['cert'] + '\nup /tmp/evil'), ('port', 22)]:
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.ns['config']({**valid, field: value})


if __name__ == '__main__':
    unittest.main()
