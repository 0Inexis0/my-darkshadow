"""Exercise V5.02 diagnostic privacy and the confirmation/command boundary."""
import os
from pathlib import Path
import pty
import subprocess
import tempfile
import unittest


DOCTOR = Path(__file__).resolve().parents[1] / "bin" / "rice-doctor"


class DoctorTests(unittest.TestCase):
    def test_default_report_excludes_private_log_and_opt_in_includes(self):
        with tempfile.TemporaryDirectory() as home:
            cache = Path(home) / ".cache"
            logs = cache / "rice"
            reports = cache / "quickshell/crashes/fixture"
            logs.mkdir(parents=True)
            reports.mkdir(parents=True)
            (logs / "desktop.log").write_text("fixture-private-desktop-message\n")
            (reports / "report.txt").write_text("fixture-private-crash-message\n")
            env = {**os.environ, "HOME": home, "PATH": "/usr/bin:/bin"}
            report = subprocess.check_output(["bash", str(DOCTOR), "report"], env=env, text=True)
            self.assertNotIn("fixture-private-", report)
            self.assertIn("crashed 1 time(s)", report)
            log_report = subprocess.check_output(["bash", str(DOCTOR), "report", "--logs"], env=env, text=True)
            self.assertIn("fixture-private-desktop-message", log_report)
            self.assertIn("fixture-private-crash-message", log_report)
            self.assertIn("review them", log_report.lower())

    def test_pipe_even_with_yes_is_rejected(self):
        result = subprocess.run(["bash", str(DOCTOR), "nvidia-fix"], input="yes\n", text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Nothing changed", result.stderr)
        self.assertIn("interactive terminal", result.stderr)

    @unittest.skipIf(os.geteuid() == 0, "production doctor deliberately refuses a root caller")
    def test_simulated_no_yes_and_rebuild_failure(self):
        # Isolate every host-dependent result. Only the actual function and
        # its confirmation/argv construction are exercised in this sandbox.
        functions = DOCTOR.read_text().split('\nusage() {', 1)[0]
        setup = r'''
nv_card() { return 0; }
egl_wl() { return 1; }
system_bin() {
  case "$1" in
    sudo) printf '%s\n' sudo_mock ;;
    install|mkinitcpio|pacman) printf '/usr/mock/%s\n' "$1" ;;
    *) return 1 ;;
  esac
}
sudo_mock() {
  printf '%s\n' "$*" >> "$calls"
  if [ "$2" = /usr/mock/install ]; then
    cat > "$captured"
  elif [ "$2" = /usr/mock/mkinitcpio ] && [ "$fail_rebuild" = 1 ]; then
    return 1
  fi
}
'''
        with tempfile.TemporaryDirectory() as tmp:
            calls = Path(tmp) / "calls"
            captured = Path(tmp) / "body"
            # These platforms force the declarative fallback by design.
            if any(Path(p).exists() for p in ("/etc/NIXOS", "/run/current-system", "/run/ostree-booted")):
                self.skipTest("host has a declarative boot-image marker")
            for reply, failure in (("n", False), ("y", False), ("y", True)):
                calls.unlink(missing_ok=True)
                captured.unlink(missing_ok=True)
                env = {**os.environ, "calls": str(calls), "captured": str(captured),
                       "fail_rebuild": "1" if failure else "0"}
                master, slave = pty.openpty()
                try:
                    child = subprocess.Popen(["bash", "-c", functions + setup + "\nnvidia_fix"],
                                             stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                             text=True, env=env)
                    os.write(master, (reply + "\n").encode())
                    stdout, stderr = child.communicate(timeout=10)
                finally:
                    os.close(slave)
                    os.close(master)
                if reply == "n":
                    self.assertFalse(calls.exists())
                    self.assertIn("Nothing changed.", stdout)
                    continue
                self.assertEqual(captured.read_text(), "options nvidia_drm modeset=1 fbdev=1\n")
                self.assertEqual(calls.read_text().splitlines(), [
                    "-- /usr/mock/pacman -S --needed egl-wayland",
                    "-- /usr/mock/install -T --backup=numbered -m 0644 -- /dev/stdin /etc/modprobe.d/darkshadow-nvidia.conf",
                    "-- /usr/mock/mkinitcpio -P",
                ])
                if failure:
                    self.assertNotEqual(child.returncode, 0)
                    self.assertIn("configuration was written", stderr)
                    self.assertNotIn("updated. Restart", stdout)
                else:
                    self.assertEqual(child.returncode, 0)
                    self.assertIn("configuration and boot image updated", stdout)
