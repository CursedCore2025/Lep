# Load user32.dll for global Home key detection
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class KeyboardListener {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

# Set folder paths
$sourceRoot = "D:\natty"
$modPath    = Join-Path $sourceRoot "mod"
$mainPath   = Join-Path $sourceRoot "main"

# Automatically find the discord_voice path inside DiscordPTB
function Get-DiscordVoicePath {
    $basePath = "$env:LOCALAPPDATA\DiscordPTB"
    if (-not (Test-Path $basePath)) { return $null }

    $appFolder = Get-ChildItem -Path $basePath -Directory | Where-Object { $_.Name -like "app-*" } | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $appFolder) { return $null }

    $modulesPath = Join-Path $appFolder.FullName "modules"
    if (-not (Test-Path $modulesPath)) { return $null }

    $discordVoiceFolder = Get-ChildItem -Path $modulesPath -Directory | Where-Object { $_.Name -like "discord_voice-*" } | Select-Object -First 1
    if (-not $discordVoiceFolder) { return $null }

    $finalPath = Join-Path $discordVoiceFolder.FullName "discord_voice"
    return $finalPath
}

# Home key virtual code
$HOME_KEY = 0x24
$lastState = $false

# Check if modded (by checking for 'node_modules' in target folder)
function IsModded($targetPath) {
    $nodeModulesPath = Join-Path $targetPath "node_modules"
    return (Test-Path $nodeModulesPath)
}

# Delete and replace the target folder with selected source
function ReplaceFolder($fromPath, $toPath) {
    try {
        if (Test-Path $toPath) {
            Remove-Item -Path $toPath -Recurse -Force -ErrorAction Stop
            Write-Host "`n🗑️ Deleted existing folder: $toPath"
        }

        Copy-Item $fromPath -Destination $toPath -Recurse -Force -ErrorAction Stop
        Write-Host "✅ Copied new files from '$fromPath' to '$toPath' at $(Get-Date)`n"
    }
    catch {
        Write-Host "`n❌ Error during folder replacement: $_`n"
    }
}

# Begin main loop
Write-Host "🟢 Script is running. Press [Home] to toggle MOD/DEFAULT version. Press Ctrl+C to stop."

while ($true) {
    Start-Sleep -Milliseconds 100
    $state = [KeyboardListener]::GetAsyncKeyState($HOME_KEY) -band 0x8000

    if ($state -and -not $lastState) {
        $targetPath = Get-DiscordVoicePath

        if (-not $targetPath) {
            Write-Host "`n❌ Could not find discord_voice folder automatically.`n"
        }
        else {
            if (IsModded $targetPath) {
                ReplaceFolder -fromPath $mainPath -toPath $targetPath
                Write-Host "➡️ Switched to DEFAULT version."
            } else {
                ReplaceFolder -fromPath $modPath -toPath $targetPath
                Write-Host "➡️ Switched to MODDED version."
            }
        }

        Start-Sleep -Seconds 1
    }

    $lastState = $state
}
