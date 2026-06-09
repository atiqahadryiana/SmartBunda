param(
    [int]$Epochs = 60,
    [int]$FrozenEpochs = 15,
    [int]$BatchSize = 32,
    [double]$LearningRate = 0.001,
    [double]$FineTuneLearningRate = 0.00001,
    [double]$ValidationSplit = 0.2,
    [int]$Seed = 42,
    [double]$Dropout = 0.3,
    [ValidateSet("mobilenet_v3_small", "mobilenet_v2", "efficientnet_b0")]
    [string]$Backbone = "efficientnet_b0",
    [ValidateSet("imagenet", "none")]
    [string]$BackboneWeights = "imagenet",
    [int]$UnfreezeLayers = 20,
    [double]$L2Weight = 0.0001,
    [int]$MinImagesPerClass = 40,
    [switch]$NoTflite,
    [string]$DatasetDir = "dataset",
    [string]$OutputDir = "artifacts",
    [string]$AppAssetsDir = "..\assets\ml"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$uvPythonDir = Join-Path $repoRoot ".uv-python"
$managedPython = Join-Path $uvPythonDir "cpython-3.11.15-windows-x86_64-none\python.exe"
$venvDir = Join-Path $scriptDir ".venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"
$uvCacheDir = Join-Path $scriptDir ".uv-cache"
$tempDir = Join-Path $scriptDir ".tmp"
$requirementsPath = Join-Path $scriptDir "requirements-ml.txt"
$trainScript = Join-Path $scriptDir "train_cnn.py"

New-Item -ItemType Directory -Force $uvCacheDir | Out-Null
New-Item -ItemType Directory -Force $tempDir | Out-Null

$env:UV_CACHE_DIR = $uvCacheDir
$env:TEMP = $tempDir
$env:TMP = $tempDir

function Get-HostPython {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCommand) {
        throw "Python was not found on PATH. Install Python first, then rerun this script."
    }
    return $pythonCommand.Source
}

function Ensure-Uv {
    $hostPython = Get-HostPython
    try {
        & $hostPython -m uv --version | Out-Null
    } catch {
        & $hostPython -m pip install --user uv
    }
    return $hostPython
}

function Ensure-ManagedPython {
    param([string]$HostPython)

    if (-not (Test-Path $managedPython)) {
        & $HostPython -m uv python install 3.11 --install-dir $uvPythonDir --managed-python --no-registry
    }
}

function Ensure-Venv {
    param([string]$HostPython)

    if (-not (Test-Path $venvPython)) {
        & $HostPython -m uv venv $venvDir --python $managedPython --allow-existing
    }
}

function Install-Requirements {
    param([string]$HostPython)

    & $HostPython -m uv pip install --python $venvPython -r $requirementsPath --no-progress
}

$hostPython = Ensure-Uv
Ensure-ManagedPython -HostPython $hostPython
Ensure-Venv -HostPython $hostPython
Install-Requirements -HostPython $hostPython

$trainArgs = @(
    $trainScript,
    "--dataset-dir", $DatasetDir,
    "--output-dir", $OutputDir,
    "--epochs", $Epochs,
    "--frozen-epochs", $FrozenEpochs,
    "--batch-size", $BatchSize,
    "--learning-rate", $LearningRate,
    "--fine-tune-learning-rate", $FineTuneLearningRate,
    "--validation-split", $ValidationSplit,
    "--seed", $Seed,
    "--dropout", $Dropout,
    "--backbone", $Backbone,
    "--backbone-weights", $BackboneWeights,
    "--unfreeze-layers", $UnfreezeLayers,
    "--l2-weight", $L2Weight,
    "--min-images-per-class", $MinImagesPerClass,
    "--app-assets-dir", $AppAssetsDir
)

if ($NoTflite) {
    $trainArgs += "--no-tflite"
}

Push-Location $scriptDir
try {
    & $venvPython @trainArgs
} finally {
    Pop-Location
}
