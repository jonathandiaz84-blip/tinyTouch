#!/usr/bin/env python3
"""Create smartcard main/secrets.h from four local PEM files.

The output contains private key material. It is intentionally gitignored.
"""

from __future__ import annotations

import argparse
from pathlib import Path


def c_string(name: str, value: str) -> str:
    lines = value.strip().splitlines()
    encoded = "\n".join(f'"{line.replace(chr(34), chr(92) + chr(34))}\\n"' for line in lines)
    return f"static const char {name}[] =\n{encoded};\n"


def read_pem(path: Path, marker: str) -> str:
    value = path.read_text(encoding="ascii")
    if f"-----BEGIN {marker}" not in value or f"-----END {marker}" not in value:
        raise SystemExit(f"{path} does not contain a {marker} PEM block")
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cert-9a", type=Path, required=True)
    parser.add_argument("--key-9a", type=Path, required=True)
    parser.add_argument("--cert-9d", type=Path, required=True)
    parser.add_argument("--key-9d", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    blocks = [
        c_string("PIV_CERT_9A_PEM", read_pem(args.cert_9a, "CERTIFICATE")),
        c_string("PIV_PRIVATE_KEY_9A_PEM", read_pem(args.key_9a, "PRIVATE KEY")),
        c_string("PIV_CERT_9D_PEM", read_pem(args.cert_9d, "CERTIFICATE")),
        c_string("PIV_PRIVATE_KEY_9D_PEM", read_pem(args.key_9d, "PRIVATE KEY")),
    ]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("#pragma once\n\n" + "\n".join(blocks), encoding="ascii")
    args.output.chmod(0o600)
    print(f"Wrote {args.output} with mode 0600. Do not commit it.")


if __name__ == "__main__":
    main()
