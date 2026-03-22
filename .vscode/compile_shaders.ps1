$ErrorActionPreference = 'Stop'

$shaderDir = Join-Path $PSScriptRoot "../Resources/Shaders"
$shaderDir = [System.IO.Path]::GetFullPath($shaderDir)

$compiledCount = 0
$skippedCount = 0

Get-ChildItem -Path $shaderDir -Recurse -File |
Where-Object { $_.Extension -in '.vert', '.frag' } |
ForEach-Object {
    $src = $_.FullName
    $out = $src + ".spv"

    $needsCompile = $false

    if (-not (Test-Path $out)) {
        $needsCompile = $true
    }
    else {
        $srcTime = (Get-Item $src).LastWriteTimeUtc
        $outTime = (Get-Item $out).LastWriteTimeUtc

        if ($srcTime -gt $outTime) {
            $needsCompile = $true
        }
    }

    if ($needsCompile) {
        Write-Host "Compiling $src -> $out"
        & glslc $src -o $out
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        $compiledCount++
    }
    else {
        Write-Host "Up to date: $src"
        $skippedCount++
    }
}

Write-Host ""
Write-Host "Shaders compiled: $compiledCount"
Write-Host "Shaders skipped:  $skippedCount"