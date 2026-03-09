#!/usr/bin/env bash
set -euo pipefail

if rg -n "import (UIKit|AppKit|CoreData|WebKit)" Sources/AidokuCore; then
  echo "error: Apple-only framework import found inside Sources/AidokuCore"
  exit 1
fi

echo "OK: AidokuCore is free of Apple-only imports"
