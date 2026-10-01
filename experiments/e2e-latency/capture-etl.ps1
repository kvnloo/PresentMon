param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "replay")]
    [string]$Action,

    [string]$OutputDir = ("presentmon-etl-{0}" -f (Get-Date -Format "yyyyMMdd-HHmmss")),

    [string]$XperfExe = "xperf.exe",

    [string]$PresentMonExe
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$startScript = Join-Path $repoRoot "Tools\start_etl_collection.cmd"
$stopScript = Join-Path $repoRoot "Tools\stop_etl_collection.cmd"

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "ETL start/stop must run from an Administrator PowerShell."
    }
}

function Resolve-OutputDir {
    param([string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    return (Resolve-Path $Path).Path
}

switch ($Action) {
    "start" {
        Assert-Admin
        $dir = Resolve-OutputDir $OutputDir

        & (Join-Path $PSScriptRoot "capture-env.ps1") -OutputPath (Join-Path $dir "environment.txt")

        Push-Location $dir
        try {
            $commandLine = '"' + $startScript + '" "' + $XperfExe + '"'
            & cmd.exe /c $commandLine
            if ($LASTEXITCODE -ne 0) {
                throw "ETL collection failed to start (exit $LASTEXITCODE)."
            }
            Set-Content -Path "capture-started.txt" -Value ((Get-Date).ToString("o"))
        }
        finally {
            Pop-Location
        }

        Write-Host "ETL capture started. Reproduce the issue briefly, then run stop with the same OutputDir."
    }

    "stop" {
        Assert-Admin
        $dir = (Resolve-Path $OutputDir).Path

        Push-Location $dir
        try {
            $commandLine = '"' + $stopScript + '" "' + $XperfExe + '"'
            & cmd.exe /c $commandLine
            if ($LASTEXITCODE -ne 0) {
                throw "ETL collection failed to stop cleanly (exit $LASTEXITCODE)."
            }
            Set-Content -Path "capture-stopped.txt" -Value ((Get-Date).ToString("o"))
        }
        finally {
            Pop-Location
        }

        $trace = Join-Path $dir "trace.etl"
        if (-not (Test-Path $trace)) {
            throw "Capture stopped but trace.etl was not produced in $dir."
        }

        Write-Host "ETL capture written to $trace"
    }

    "replay" {
        if (-not $PresentMonExe) {
            throw "-PresentMonExe is required for replay."
        }

        $dir = (Resolve-Path $OutputDir).Path
        $trace = Join-Path $dir "trace.etl"
        if (-not (Test-Path $trace)) {
            throw "Missing $trace"
        }

        $csv = Join-Path $dir "replay.csv"
        & $PresentMonExe -etl_file $trace -output_file $csv
        if ($LASTEXITCODE -ne 0) {
            throw "PresentMon replay failed (exit $LASTEXITCODE)."
        }

        Write-Host "Replay CSV written to $csv"
    }
}
