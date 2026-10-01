param(
    [string]$OutputPath = ("presentmon-latency-env-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
)

$lines = [System.Collections.Generic.List[string]]::new()

function Add-CommandResult {
    param([string]$Label, [scriptblock]$Command)

    $lines.Add("")
    $lines.Add("$ $Label")
    try {
        $result = & $Command 2>&1 | Out-String
        $lines.Add($result.TrimEnd())
    } catch {
        $lines.Add("ERROR: $($_.Exception.Message)")
    }
}

$lines.Add("captured_at=$((Get-Date).ToString('o'))")
Add-CommandResult "git rev-parse HEAD" { git rev-parse HEAD }
Add-CommandResult "Windows version" { Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber }
Add-CommandResult "CPU" { Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors }
Add-CommandResult "GPU" { Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate }
Add-CommandResult "Display" { Get-CimInstance Win32_DesktopMonitor | Select-Object Name, ScreenWidth, ScreenHeight, Status }

$lines | Set-Content -Path $OutputPath -Encoding utf8
Write-Host "wrote $OutputPath"
