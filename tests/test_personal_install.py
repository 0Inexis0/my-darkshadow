"""Installation checks use temporary homes and never partition a real disk."""
import importlib.util
from importlib.machinery import SourceFileLoader
import json
import contextlib
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name, relative):
    loader = SourceFileLoader(name, str(ROOT / relative))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


apply = load("personal_apply", "personal/apply.py")
configure = load("configure", "personal/configure-system.py")
disk = load("install_disk", "personal/install-to-disk.py")
publication = load("publication", "personal/check-publication.py")
updater = load("fork_updater", "bin/rice-update")
release = load("package_release", "personal/package-release.py")


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.source, self.home = root / "source", root / "home"
        for folder in ["config/app", "personal", "assets", "bin", "settings"]:
            (self.source / folder).mkdir(parents=True)
        (self.source / "VERSION").write_text("4.33\n")
        (self.source / "personal/FORK_VERSION").write_text("1.0.0\n")
        (self.source / "assets/icon.png").write_bytes(b"image")
        (self.source / "config/app/test.conf").write_text("home=@HOME@\nuser=@USER@\n")

    def test_initial_replace_is_backed_up_and_subsequent_local_edit_survives(self):
        target = self.home / ".config/app/test.conf"
        target.parent.mkdir(parents=True)
        target.write_text("old configuration")
        apply.deploy(self.source, self.home, "alice")
        self.assertEqual(target.read_text(), f"home={self.home}\nuser=alice\n")
        backups = list((self.home / ".local/state/my-darkshadow/backups").glob("*/.config/app/test.conf"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "old configuration")
        target.write_text("local edit")
        (self.source / "config/app/test.conf").write_text("new upstream value")
        result = apply.deploy(self.source, self.home, "alice")
        self.assertEqual(result["kept"], 1)
        self.assertEqual(target.read_text(), "local edit")
        apply.deploy(self.source, self.home, "alice", force=True)
        self.assertEqual(target.read_text(), "new upstream value")

    def test_dry_run_does_not_create_home_or_manifest(self):
        apply.deploy(self.source, self.home, "alice", dry_run=True)
        self.assertFalse(self.home.exists())

    def test_cli_cannot_write_user_controlled_paths_as_root(self):
        with patch.object(apply.os, "geteuid", return_value=0), \
             patch("sys.argv", ["apply.py", "--dry-run"]), \
             contextlib.redirect_stderr(io.StringIO()), patch.object(apply, "deploy") as deploy:
            with self.assertRaises(SystemExit) as stopped:
                apply.main()
            self.assertEqual(stopped.exception.code, 2)
            deploy.assert_not_called()

    def test_symlink_directory_cannot_redirect_root_deployment(self):
        outside = self.home.parent / "outside"
        outside.mkdir()
        (self.home / ".config").mkdir(parents=True)
        (self.home / ".config/app").symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "outside home"):
            apply.deploy(self.source, self.home, "alice")
        self.assertFalse((outside / "test.conf").exists())

    def test_legion_values_are_optional_and_generic_has_no_forced_panel(self):
        generic = json.loads((ROOT / "settings/rice/hypr.json").read_text())
        legion = json.loads((ROOT / "personal/profiles/legion/hypr.json").read_text())
        self.assertEqual(generic["monitors"], {})
        self.assertEqual(legion["monitors"]["eDP-2"]["scale"], 1.6)


class InstallerSafetyTests(unittest.TestCase):
    def test_mounts_on_child_partitions_exclude_the_whole_disk(self):
        devices = [
            {"path": "/dev/sda", "type": "disk", "ro": False,
             "children": [{"mountpoints": [None], "children": [{"mountpoints": ["/"]}]}]},
            {"path": "/dev/sdb", "type": "disk", "ro": True},
            {"path": "/dev/sdc", "type": "disk", "ro": False, "mountpoints": [None]},
            {"path": "/dev/loop0", "type": "loop", "ro": False},
        ]
        self.assertEqual([d["path"] for d in disk.available_disks(devices)], ["/dev/sdc"])

    def test_partition_commands_use_correct_nvme_and_sata_names(self):
        for device, expected in [("/dev/nvme0n1", "/dev/nvme0n1p2"), ("/dev/sda", "/dev/sda2")]:
            commands = disk.partition_plan(device)
            mkfs = next(c for c in commands if c[0] == "mkfs.ext4")
            self.assertEqual(mkfs[-1], expected)
            self.assertEqual(commands[0], ["wipefs", "--all", device])
            self.assertIn(["mount", "-t", "ext4", expected, "/mnt"], commands)
            self.assertIn(["mount", "-t", "vfat", disk.partition_name(device, 1), "/mnt/boot"], commands)

    def test_account_names_cannot_inject_shell_or_nix(self):
        for value in ["root", "nixos", "a;reboot", 'a"; builtins.abort "', "../home", ""]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                configure.identifier(value)
        self.assertEqual(configure.identifier("alice"), "alice")

    def test_import_is_idempotent_and_other_settings_are_preserved(self):
        original = '{ imports = [ ./hardware-configuration.nix ]; networking.hostName = "existing"; }'
        updated = configure.insert_import(original)
        self.assertIn('networking.hostName = "existing"', updated)
        self.assertEqual(updated.count("./my-darkshadow.nix"), 1)
        self.assertEqual(configure.insert_import(updated), updated)
        with self.assertRaises(ValueError):
            configure.insert_import("{ noImports = true; }")

    def test_new_system_contains_no_default_password_and_keeps_hardware(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)
            hardware = target / "hardware-configuration.nix"
            hardware.write_text("{ fileSystems = {}; }")
            configure.configure(ROOT, target, "alice", "generic", new_host="desktop")
            generated = (target / "configuration.nix").read_text()
            self.assertIn('./hardware-configuration.nix', generated)
            self.assertIn('root.hashedPassword = "!"', generated)
            self.assertNotIn("initialPassword", generated)
            self.assertEqual(hardware.read_text(), "{ fileSystems = {}; }")

    def test_nixos_check_compares_fork_main_without_using_store_checkout(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "managed-by-nixos").touch()
            (root / "fork-revision").write_text("a" * 40)
            result = subprocess.CompletedProcess([], 0, "b" * 40 + "\trefs/heads/main\n", "")
            with patch.object(updater, "DIR", directory), patch.object(updater, "CACHE", directory), \
                 patch.object(updater, "STATE", str(root / "update.json")), \
                 patch.object(updater, "installed", return_value="4.35"), \
                 patch.object(updater, "git", return_value=result) as git, \
                 patch.object(updater, "repo", side_effect=AssertionError("must not touch store checkout")):
                self.assertTrue(updater.check()["update"])
                git.assert_called_once_with(updater.HOME, "ls-remote", updater.NEW_URL, "refs/heads/main")
                self.assertFalse(updater.check(offline=True)["update"])

    def test_managed_button_opens_terminal_instead_of_legacy_installer(self):
        with patch.object(updater, "managed", return_value=True), \
             patch.object(updater, "terminal_update") as terminal, \
             patch.object(updater, "gui", side_effect=AssertionError("legacy installer called")):
            self.assertEqual(updater.main(["rice-update", "gui"]), 0)
            terminal.assert_called_once()

    def test_update_checkout_keeps_local_edits_without_reset_or_rebuild(self):
        dirty = subprocess.CompletedProcess([], 0, " M bin/rice-clip\n", "")
        with patch.object(updater.os.path, "exists", return_value=True), \
             patch.object(updater.os.path, "isdir", return_value=True), \
             patch.object(updater, "git", return_value=dirty) as git:
            with self.assertRaisesRegex(RuntimeError, "Local edits"):
                updater.managed_checkout()
            self.assertEqual(git.call_count, 1)

    def test_failed_nixos_build_keeps_profile_and_never_reports_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "personal-profile").write_text("legion\n")
            revision = subprocess.CompletedProcess([], 0, "a" * 12, "")
            with patch.object(updater, "DIR", directory), patch.object(updater, "CACHE", directory), \
                 patch.object(updater, "LIVE_LOG", str(root / "log")), \
                 patch.object(updater, "managed_checkout", return_value=directory), \
                 patch.object(updater, "git", return_value=revision), \
                 patch.object(updater, "put_live") as state, \
                 patch.object(updater.subprocess, "call", return_value=1) as build, \
                 patch("builtins.input", return_value=""), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(updater.managed_run(), 1)
                self.assertEqual(build.call_args.args[0][-2:], ["--profile", "legion"])
                self.assertEqual(state.call_args.kwargs["state"], "failed")
                self.assertFalse(state.call_args.kwargs["reboot"])

    def test_nixos_revision_survives_source_snapshot_and_deployment(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            configure.configure(ROOT, root, "alice", "generic", new_host="desktop")
            revision = (root / "my-darkshadow/source/personal/REVISION").read_text().strip()
            self.assertRegex(revision, r"^[0-9a-f]{40}$")



class PublicationTests(unittest.TestCase):
    def test_credentials_are_detected_without_echoing_their_values(self):
        fake = ("ghp_" + "A" * 36).encode()
        self.assertIn("GitHub credential", publication.findings(Path("sample.txt"), fake))
        self.assertIn("private state or build product", publication.findings(Path(".env"), b""))
        self.assertEqual(publication.findings(Path("settings.json"), b'{"lang":"de"}'), [])


class ReleaseIntegrityTests(unittest.TestCase):
    def test_release_parts_reassemble_and_corruption_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = root / "my-darkshadow-1.0.0-generic-x86_64.iso"
            original.write_bytes(b"test image with several release parts")
            output = root / "release"
            parts = release.package(original, output, chunk_size=11)
            self.assertEqual(len(parts), 4)
            result = subprocess.run(["bash", str(output / "assemble-generic.sh")], capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            self.assertEqual((output / original.name).read_bytes(), original.read_bytes())
            (output / original.name).unlink()
            (output / parts[0][0]).write_bytes(b"corrupt")
            result = subprocess.run(["bash", str(output / "assemble-generic.sh")], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((output / original.name).exists())


if __name__ == "__main__":
    unittest.main()
