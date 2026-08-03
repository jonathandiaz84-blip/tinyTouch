import json
import tempfile
import unittest
from pathlib import Path

from desk_hub_agent import ConfigError, command_for_action, load_config, run_profile


class AgentTests(unittest.TestCase):
    def test_dry_run_profile(self):
        cfg = {"profiles": {"work": [
            {"type": "app", "name": "Codex"},
            {"type": "url", "url": "https://chatgpt.com/"},
            {"type": "shortcut", "name": "JD Work Focus"},
            {"type": "delay", "seconds": 0},
        ]}}
        commands = run_profile(cfg, "work", dry_run=True)
        self.assertEqual(commands[0], ["/usr/bin/open", "-a", "Codex"])
        self.assertEqual(len(commands), 3)

    def test_rejects_shell_action(self):
        with self.assertRaises(ConfigError):
            command_for_action({"type": "shell", "command": "rm -rf /"})

    def test_rejects_file_url(self):
        with self.assertRaises(ConfigError):
            command_for_action({"type": "url", "url": "file:///tmp/test"})

    def test_load_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "config.json"
            path.write_text(json.dumps({"profiles": {}}), encoding="utf-8")
            self.assertEqual(load_config(path), {"profiles": {}})


if __name__ == "__main__":
    unittest.main()
