#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"

python3 -m PyInstaller --noconfirm --clean --onefile --windowed \
  --name PhoenixEngineSetup \
  --add-data "assets/pe.png:assets" \
  --paths "." \
  "phoenix_setup.py"

python3 -m PyInstaller --noconfirm --clean --onefile --console \
  --name PhoenixEngineSetupCLI \
  --paths "." \
  "phoenix_setup_cli.py"

printf 'Created: dist/PhoenixEngineSetup and dist/PhoenixEngineSetupCLI\n'
