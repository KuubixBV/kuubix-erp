$customDir = ".\custom"
$deployScript = ".\custom\deploy.sh"

# Check if the directory exists
if (-Not (Test-Path $customDir)) {
    Write-Host "Error: $customDir does not exist."
    exit 1
}

# Get the initial state of directories
$fsWatcher = New-Object System.IO.FileSystemWatcher
$fsWatcher.Path = $customDir
$fsWatcher.IncludeSubdirectories = $true
$fsWatcher.EnableRaisingEvents = $true

Write-Host "Watching for changes in $customDir..."

$action = {
    $eventPath = $Event.SourceEventArgs.FullPath
    $folderName = Split-Path $eventPath -Leaf

    Write-Host "Change detected in $folderName. Deploying..."
    bash.exe $deployScript --folder $folderName
}

Register-ObjectEvent $fsWatcher "Created" -Action $action
Register-ObjectEvent $fsWatcher "Changed" -Action $action
Register-ObjectEvent $fsWatcher "Deleted" -Action $action
Register-ObjectEvent $fsWatcher "Renamed" -Action $action

while ($true) {
    Start-Sleep 1
}

