#!/usr/bin/env python3
"""Explicit, allowlisted macOS workflow runner for JD Desk Hub.

This process is intentionally independent from fingerprint/PIV authentication.
It does not accept shell commands and does not store credentials.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import urlparse


class ConfigError(ValueError):
    pass


def load_config(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ConfigError(f"Config not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ConfigError(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(data, dict) or not isinstance(data.get("profiles"), dict):
        raise ConfigError("Config must contain a profiles object.")
    return data


def command_for_action(action: dict) -> tuple[list[str] | None, float | None]:
    if not isinstance(action, dict):
        raise ConfigError("Each action must be an object.")
    kind = action.get("type")
    if kind == "app":
        name = action.get("name")
        if not isinstance(name, str) or not name.strip():
            raise ConfigError("app action requires a non-empty name.")
        return ["/usr/bin/open", "-a", name], None
    if kind == "url":
        value = action.get("url")
        if not isinstance(value, str):
            raise ConfigError("url action requires a URL string.")
        parsed = urlparse(value)
        if parsed.scheme not in {"https", "http"} or not parsed.netloc:
            raise ConfigError("Only complete http/https URLs are allowed.")
        return ["/usr/bin/open", value], None
    if kind == "shortcut":
        name = action.get("name")
        if not isinstance(name, str) or not name.strip():
            raise ConfigError("shortcut action requires a non-empty name.")
        return ["/usr/bin/shortcuts", "run", name], None
    if kind == "delay":
        seconds = action.get("seconds")
        if not isinstance(seconds, (int, float)) or not 0 <= seconds <= 30:
            raise ConfigError("delay seconds must be between 0 and 30.")
        return None, float(seconds)
    raise ConfigError(f"Unsupported action type: {kind!r}")


def run_profile(config: dict, profile_name: str, dry_run: bool = False) -> list[list[str]]:
    profiles = config["profiles"]
    if profile_name not in profiles:
        raise ConfigError(f"Unknown profile: {profile_name}")
    actions = profiles[profile_name]
    if not isinstance(actions, list):
        raise ConfigError(f"Profile {profile_name} must be an array.")

    executed: list[list[str]] = []
    for action in actions:
        command, delay = command_for_action(action)
        if delay is not None:
            print(f"delay {delay:g}s")
            if not dry_run:
                time.sleep(delay)
            continue
        assert command is not None
        executed.append(command)
        print("run:", " ".join(command))
        if not dry_run:
            subprocess.run(command, check=True)
    return executed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        default=Path.home() / "Library" / "Application Support" / "JD Desk Hub" / "config.json",
    )
    parser.add_argument("--dry-run", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)
    run_parser = sub.add_parser("run", help="run a configured profile")
    run_parser.add_argument("profile")
    sub.add_parser("list", help="list profile names")
    args = parser.parse_args()

    try:
        config = load_config(args.config)
        if args.command == "list":
            print("\n".join(sorted(config["profiles"])))
        else:
            run_profile(config, args.profile, dry_run=args.dry_run)
    except (ConfigError, subprocess.CalledProcessError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
