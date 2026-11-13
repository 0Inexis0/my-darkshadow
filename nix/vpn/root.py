import ipaddress
import fcntl
import json
import os
from pathlib import Path
import re
import selectors
import signal
import subprocess
import sys
import tempfile
import time

OPENVPN = '@OPENVPN@'
RESOLVCONF = '@RESOLVCONF@'
PYTHON = '@PYTHON@'
CA = @CA@

def config(data):
    host = data['host']
    if not re.fullmatch(r'vpn[0-9]+-(?:mia|nyc|sea)\.riseup\.net', host):
        raise ValueError('Unzulässiger US-Endpunkt')
    address = str(ipaddress.IPv4Address(data['ip']))
    if data['port'] not in (53, 80, 1194):
        raise ValueError('Unzulässiger Port')
    if data['protocol'] not in ('tcp-client', 'udp'):
        raise ValueError('Unzulässiges Protokoll')
    cert = data['cert']
    key = data['key']
    if not re.fullmatch(r'-----BEGIN CERTIFICATE-----\s+[A-Za-z0-9+/=\s]+-----END CERTIFICATE-----', cert):
        raise ValueError('Ungültiges Zertifikat')
    if not re.fullmatch(r'-----BEGIN (RSA )?PRIVATE KEY-----\s+[A-Za-z0-9+/=\s]+-----END (RSA )?PRIVATE KEY-----', key):
        raise ValueError('Ungültiger Schlüssel')
    return '\n'.join([
        'client', 'dev tun-usvpn', 'dev-type tun',
        'proto ' + data['protocol'], f'remote {address} {data["port"]}',
        'remote-cert-tls server', 'verify-x509-name ' + host.split('.')[0] + ' name',
        'nobind', 'persist-key', 'auth SHA512',
        'cipher AES-256-GCM', 'data-ciphers AES-256-GCM',
        'tls-version-min 1.2', 'auth-nocache', 'verb 3',
        'connect-timeout 8', 'connect-retry-max 1', 'resolv-retry 5',
        'redirect-gateway def1 ipv6', 'block-ipv6',
        'pull-filter ignore block-outside-dns',
        '<ca>', CA.strip(), '</ca>',
        '<cert>', cert, '</cert>', '<key>', key, '</key>', ''
    ])

def dns_hook(action):
    if os.environ.get('dev') != 'tun-usvpn':
        return 1
    if action == 'down':
        subprocess.run([RESOLVCONF, '-d', 'tun-usvpn'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return 0
    servers = []
    for k, value in os.environ.items():
        if k.startswith('foreign_option_') and value.startswith('dhcp-option DNS '):
            servers.append(str(ipaddress.ip_address(value.split()[2])))
    if not servers:
        raise RuntimeError('Der VPN-Server hat keinen DNS-Server geliefert')
    subprocess.run([RESOLVCONF, '-a', 'tun-usvpn', '-m', '0', '-x'],
                   input=''.join('nameserver ' + s + '\n' for s in servers), text=True, check=True)
    return 0

def main():
    if len(sys.argv) > 1 and sys.argv[1] == '--hook':
        return dns_hook(sys.argv[2])
    if os.geteuid() != 0:
        raise RuntimeError('Für die VPN-Verbindung werden Administratorrechte benötigt')
    # All callers share one tunnel and DNS entry; a second start must never clean up the first.
    lock = open('/run/usa-vpn.lock', 'w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        raise RuntimeError('Eine USA-VPN-Verbindung läuft bereits')
    if Path('/sys/class/net/tun-usvpn').exists():
        raise RuntimeError('Eine USA-VPN-Verbindung läuft bereits')
    os.environ['PATH'] = '/run/current-system/sw/bin:/run/wrappers/bin'
    raw = sys.stdin.buffer.readline(40000)
    data = json.loads(raw)
    content = config(data)
    stop = False
    def stopping(*_):
        nonlocal stop
        stop = True
    for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(sig, stopping)
    child = None
    try:
        with tempfile.TemporaryDirectory(prefix='usa-vpn-', dir='/run') as tmp:
            cfg = Path(tmp) / 'connection.ovpn'
            cfg.write_text(content)
            cfg.chmod(0o600)
            hook = PYTHON + ' ' + str(Path(__file__).resolve()) + ' --hook '
            child = subprocess.Popen([
                OPENVPN, '--config', str(cfg), '--script-security', '2',
                '--up', hook + 'up', '--down', hook + 'down', '--down-pre',
            ], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            sel = selectors.DefaultSelector()
            sel.register(child.stdout, selectors.EVENT_READ, 'log')
            sel.register(sys.stdin.buffer, selectors.EVENT_READ, 'control')
            deadline = time.monotonic() + 35
            pending = b''
            ready = False
            while child.poll() is None and not stop:
                if not ready and time.monotonic() > deadline:
                    print('ERROR: Zeitüberschreitung beim Verbindungsaufbau', flush=True)
                    break
                for key, _ in sel.select(0.25):
                    chunk = os.read(key.fileobj.fileno(), 8192)
                    if key.data == 'control':
                        stop = True
                        break
                    if not chunk:
                        sel.unregister(key.fileobj)
                        continue
                    pending += chunk
                    while b'\n' in pending:
                        line, pending = pending.split(b'\n', 1)
                        message = line.decode(errors='replace')
                        print(message, flush=True)
                        if 'Initialization Sequence Completed' in message:
                            ready = True
                            print('USA_VPN_READY', flush=True)
            return 0 if ready and stop else 1
    finally:
        if child and child.poll() is None:
            child.send_signal(signal.SIGTERM)
            try:
                child.wait(timeout=8)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()
        subprocess.run([RESOLVCONF, '-d', 'tun-usvpn'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as exc:
        print('ERROR: ' + str(exc), flush=True)
        sys.exit(1)
