$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

$file1 = Join-Path $rootDir "planet-kit\dist\planet-kit-eval.js"
$file2 = Join-Path $rootDir "planet-kit\dist\planet-kit.js"

if (-not (Test-Path $file1)) {
    Write-Error "File not found: $file1"
    exit 1
}

if (-not (Test-Path $file2)) {
    Write-Error "File not found: $file2"
    exit 1
}

$outputFile = Join-Path $scriptDir "diff-output.txt"

Write-Host "Getting diff..."
Write-Host "File 1: $file1"
Write-Host "File 2: $file2"
Write-Host ""

try {
    $gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
    
    if ($gitAvailable) {
        Write-Host "Getting diff using git diff..."
        $oldErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        $diff = git diff --no-index "$file1" "$file2" 2>$null
        $ErrorActionPreference = $oldErrorAction
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
            $diff | Out-File -FilePath $outputFile -Encoding UTF8
            Write-Host "Diff saved to $outputFile."
            
            $diffLines = ($diff | Measure-Object -Line).Lines
            Write-Host "Number of diff lines: $diffLines"
        } else {
            throw "Failed to execute git diff."
        }
    } else {
        Write-Host "git is not available, using Compare-Object..."
        
        $content1 = Get-Content $file1 -Raw
        $content2 = Get-Content $file2 -Raw
        
        if ($content1 -eq $content2) {
            Write-Host "No differences found between files."
            "No differences found between files." | Out-File -FilePath $outputFile -Encoding UTF8
        } else {
            $lines1 = Get-Content $file1
            $lines2 = Get-Content $file2
            
            $diff = Compare-Object $lines1 $lines2 | ForEach-Object {
                $side = if ($_.SideIndicator -eq "<=") { "Left only" } else { "Right only" }
                "$side (line $($_.InputObject))"
            }
            
            $diff | Out-File -FilePath $outputFile -Encoding UTF8
            Write-Host "Diff saved to $outputFile."
        }
    }
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}

Write-Host ""
Write-Host "Completed."
