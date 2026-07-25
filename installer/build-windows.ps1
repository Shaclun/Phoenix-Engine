$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$BuildPython = Join-Path $PSScriptRoot ".venv-build\Scripts\python.exe"
if (Test-Path $BuildPython) {
  $Python = $BuildPython
  $PythonArgs = @()
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
  $Python = "py"
  $PythonArgs = @("-3")
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
  $Python = "python"
  $PythonArgs = @()
} else {
  throw "Python 3 was not found. Install Python 3.10 or newer to build the package."
}

& $Python @PythonArgs -m PyInstaller --noconfirm --clean --onefile --windowed `
  --name PhoenixEngineSetup `
  --icon "assets\pe.png" `
  --add-data "assets\pe.png;assets" `
  --version-file "version_info.txt" `
  --paths "." `
  "phoenix_setup.py"

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Created: dist\PhoenixEngineSetup.exe" -ForegroundColor Green