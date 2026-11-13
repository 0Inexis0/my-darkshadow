"""Accountless Riseup US VPN controller shared by the desktop and Settings."""
import concurrent.futures
import fcntl
import json
import os
from pathlib import Path
import queue
import re
import signal
import socket
import subprocess
import sys
import threading
import time
import urllib.request

ROOT_HELPER = '@ROOT_EXE@'
PYTHON = '@PYTHON@'
API = 'https://api.black.riseup.net/3/'
RUNTIME = Path(os.environ.get('XDG_RUNTIME_DIR', '/run/user/' + str(os.getuid()))) / 'usa-vpn'
PREFS = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'rice/vpn.json'


def runtime():
    RUNTIME.mkdir(mode=0o700, parents=True, exist_ok=True)
    return RUNTIME


def read_json(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + '.' + str(os.getpid()) + '.tmp')
    with open(tmp, 'w', opener=lambda p, flags: os.open(p, flags, 0o600)) as f:
        json.dump(data, f)
    tmp.replace(path)


def managed_worker(pid):
    try:
        p = Path('/proc') / str(int(pid))
        args = p.joinpath('cmdline').read_bytes().split(b'\0')
        return p.stat().st_uid == os.getuid() and b'_worker' in args and any(
            a.decode(errors='replace').endswith('usa-vpn-control.py') for a in args)
    except (OSError, ValueError, TypeError):
        return False


def state():
    value = read_json(runtime() / 'state.json', {})
    if value.get('status') in ('connecting', 'connected', 'disconnecting') and not managed_worker(value.get('pid')):
        value = {'status': 'disconnected'}
    value.setdefault('status', 'disconnected')
    value.update(available=Path(ROOT_HELPER).is_file() and Path('/run/wrappers/bin/pkexec').exists(),
                 provider='Riseup', country='US', preference=read_json(PREFS, {}).get('location', 'auto'))
    return value


def fetch(path, post=False):
    req = urllib.request.Request(API + path, data=b'' if post else None,
                                 headers={'User-Agent': 'my-darkshadow-vpn/1.0'})
    with urllib.request.urlopen(req, timeout=15) as response:
        return response.read(300000).decode()


def gateways():
    data = json.loads(fetch('config/eip-service.json'))
    result = [g for g in data['gateways']
              if data['locations'].get(g['location'], {}).get('country_code') == 'US'
              and re.fullmatch(r'vpn[0-9]+-(?:mia|nyc|sea)\.riseup\.net', g['host'])]
    if not result:
        raise RuntimeError('No US servers are available. Please try again later.')
    return result


def locations():
    places = sorted({g['location'] for g in gateways()})
    return [{'value': 'auto', 'label': 'Fastest US server'}] + [
        {'value': p, 'label': 'New York' if p == 'New York City' else p} for p in places]


def prepare():
    servers = gateways()
    location = read_json(PREFS, {}).get('location', 'auto')
    if location != 'auto':
        servers = [g for g in servers if g['location'] == location]
        if not servers:
            raise RuntimeError('This US location is unavailable. Choose Automatic or try again later.')
    pem = fetch('cert', post=True)
    cert = re.search(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----', pem, re.S)
    key = re.search(r'-----BEGIN (?:RSA )?PRIVATE KEY-----.*?-----END (?:RSA )?PRIVATE KEY-----', pem, re.S)
    if not cert or not key:
        raise RuntimeError('The provider could not issue a connection certificate.')
    def ping(g):
        start = time.monotonic()
        try:
            with socket.create_connection((g['ip_address'], 1194), timeout=3):
                return time.monotonic() - start, g
        except OSError:
            return 999, g
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        ranked = sorted(pool.map(ping, servers), key=lambda x: x[0])
    return [dict(host=g['host'], ip=g['ip_address'], port=1194,
                 protocol='tcp-client', cert=cert.group(), key=key.group(), location=g['location'])
            for _, g in ranked[:4]]


def stop_tunnel(proc):
    if proc and proc.poll() is None:
        try:
            proc.stdin.write('stop\n')
            proc.stdin.flush()
            proc.stdin.close()
        except (BrokenPipeError, OSError):
            pass
        try:
            proc.wait(timeout=12)
        except subprocess.TimeoutExpired:
            proc.terminate()
            proc.wait(timeout=5)


def start():
    with open(runtime() / 'launch.lock', 'w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        value = state()
        if value['status'] in ('connecting', 'connected', 'disconnecting'):
            return value
        if not value['available']:
            raise RuntimeError('VPN support is not installed on this desktop.')
        with open(runtime() / 'worker.log', 'w') as log:
            proc = subprocess.Popen([PYTHON, '-I', str(Path(__file__).resolve()), '_worker'],
                                    stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True)
        value = {'status': 'connecting', 'pid': proc.pid, 'started': time.time(), 'message': ''}
        save(runtime() / 'state.json', value)
        return value


def disconnect():
    with open(runtime() / 'launch.lock', 'w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        value = state()
        if managed_worker(value.get('pid')):
            value.update(status='disconnecting', message='')
            save(runtime() / 'state.json', value)
            try:
                os.kill(value['pid'], signal.SIGTERM)
            except ProcessLookupError:
                pass
        return value


def exit_country():
    for url in ('https://ipinfo.io/json', 'https://ipapi.co/json/'):
        try:
            with urllib.request.urlopen(url, timeout=7) as r:
                info = json.load(r)
            country = info.get('country') or info.get('country_code')
            if country:
                return country, info.get('ip', '')
        except Exception:
            continue
    return None, ''


def worker():
    lock = open(runtime() / 'worker.lock', 'w')
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return 0
    stopping = False
    def stop(*_):
        nonlocal stopping
        stopping = True
    for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(sig, stop)
    # Serialize startup with start()/disconnect() so a fast worker cannot overwrite a stop request.
    with open(runtime() / 'launch.lock', 'w') as startup:
        fcntl.flock(startup, fcntl.LOCK_EX)
    current = dict(pid=os.getpid(), status='connecting', started=time.time(), message='')
    proc = None
    error = ''
    try:
        choices = prepare()
        for choice in choices:
            if stopping:
                break
            current.update(status='connecting', location=choice['location'])
            save(runtime() / 'state.json', current)
            proc = subprocess.Popen(['/run/wrappers/bin/pkexec', ROOT_HELPER],
                                    stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True, bufsize=1)
            proc.stdin.write(json.dumps(choice) + '\n')
            proc.stdin.flush()
            events = queue.Queue()
            def reader(stream, output):
                for line in stream:
                    output.put(line.rstrip())
                output.put(None)
            threading.Thread(target=reader, args=(proc.stdout, events), daemon=True).start()
            ready = False
            deadline = time.monotonic() + 55
            while not stopping:
                try:
                    line = events.get(timeout=.25)
                except queue.Empty:
                    if not ready and time.monotonic() > deadline:
                        break
                    continue
                if line is None:
                    break
                if line == 'USA_VPN_READY':
                    country, address = exit_country()
                    if country and country != 'US':
                        raise RuntimeError('The exit IP is not in the United States. The VPN was disconnected.')
                    if stopping:
                        break
                    ready = True
                    current.update(status='connected', location=choice['location'], verified=country == 'US',
                                   ip=address, connected_at=time.time())
                    save(runtime() / 'state.json', current)
                elif ('SIGUSR1' in line and 'ping-restart' in line) or 'Restart pause' in line:
                    ready = False
                    deadline = time.monotonic() + 55
                    current.update(status='connecting', verified=False, ip='')
                    save(runtime() / 'state.json', current)
            stop_tunnel(proc)
            proc = None
            if ready or stopping:
                if ready and not stopping:
                    error = 'The VPN connection was interrupted. Please reconnect.'
                break
        else:
            error = 'Could not connect to a US server. Please try again.'
    except Exception as exc:
        error = str(exc) if isinstance(exc, RuntimeError) else 'Could not reach the VPN provider. Check your internet connection.'
    finally:
        stop_tunnel(proc)
        save(runtime() / 'state.json', {'status': 'error' if error and not stopping else 'disconnected',
                                       'message': error if not stopping else ''})
        lock.close()
    return 0


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'toggle'
    if action == '_worker':
        return worker()
    if action == 'state':
        result = state()
    elif action in ('connect', 'start'):
        result = start()
    elif action in ('disconnect', 'stop'):
        result = disconnect()
    elif action == 'toggle':
        result = disconnect() if state()['status'] in ('connected', 'connecting') else start()
    elif action == 'locations':
        result = locations()
    elif action == 'set-location':
        value = sys.argv[2]
        if value not in ('auto', 'Miami', 'Seattle', 'New York City'):
            raise ValueError('Unknown US location')
        if state()['status'] in ('connected', 'connecting', 'disconnecting'):
            raise RuntimeError('Disconnect before choosing another location.')
        prefs = read_json(PREFS, {})
        prefs['location'] = value
        save(PREFS, prefs)
        result = state()
    else:
        raise ValueError('Usage: usa-vpn state|connect|disconnect|toggle|locations|set-location LOCATION')
    print(json.dumps(result))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as exc:
        print(json.dumps({'status': 'error', 'message': str(exc)}))
        sys.exit(1)
