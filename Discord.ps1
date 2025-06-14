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
$sourceRoot   = "D:\natty"
$modPath      = Join-Path $sourceRoot "mod"
$mainPath     = Join-Path $sourceRoot "main"
$targetPath   = "C:\Users\mny pglu\AppData\Local\DiscordPTB\app-1.0.1148\modules\discord_voice-1\discord_voice"

# Home key virtual code
$HOME_KEY     = 0x24
$lastState    = $false

# Check if modded (by checking for 'node_modules' in target folder)
function IsModded {
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
        if (IsModded) {
            ReplaceFolder -fromPath $mainPath -toPath $targetPath
            Write-Host "➡️ Switched to DEFAULT version."
        } else {
            ReplaceFolder -fromPath $modPath -toPath $targetPath
            Write-Host "➡️ Switched to MODDED version."
        }

        Start-Sleep -Seconds 1
    }

    $lastState = $state
}
