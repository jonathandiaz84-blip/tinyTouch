#!/bin/zsh
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
firmware_dir="$repo_dir/firmware/tiny_touch_smartcard"

if ! command -v idf.py >/dev/null 2>&1; then
  print -u2 "idf.py is not active. Install/activate ESP-IDF 5.3.2 first."
  exit 2
fi

if [[ ! -f "$firmware_dir/main/secrets.h" ]]; then
  print -u2 "Missing main/secrets.h. Generate local PIV keys and create the header first."
  exit 2
fi

print "Git commit: $(git -C "$repo_dir" rev-parse HEAD)"
idf.py --version

cd "$firmware_dir"
idf.py set-target esp32s3
idf.py reconfigure
idf.py build

print "Build artifacts:"
for artifact in build/bootloader/bootloader.bin build/partition_table/partition-table.bin build/tiny_touch_smartcard.bin; do
  if [[ -f "$artifact" ]]; then
    shasum -a 256 "$artifact"
  fi
done
