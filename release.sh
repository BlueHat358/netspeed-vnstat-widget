#!/usr/bin/env bash
set -euo pipefail

version="${1:-1.0}"
out="netspeed-vnstat-widget-${version}.plasmoid"

if [ -e "$out" ]; then
    echo "File `$out` already exists"
    exit 1
fi

pushd package >/dev/null

if command -v zip >/dev/null 2>&1; then
    zip -r "../$out" .
elif command -v 7z >/dev/null 2>&1; then
    7z a -tzip "../$out" .
else
    echo "Need either zip or 7z to create the .plasmoid package" >&2
    exit 1
fi

popd >/dev/null

echo "Created $out"
