[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$projects = @(
    'five_level_200MHz_with_all_branch',
    'five_level_area_250M'
)
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($name in $projects) {
    $projectDir = Join-Path $repoRoot $name
    $xprPath = Join-Path $projectDir 'digital_twin.xpr'
    $sourceDir = Join-Path $projectDir 'digital_twin.srcs'
    $rtlDir = Join-Path $sourceDir 'sources_1\rtl'

    if (-not (Test-Path -LiteralPath $xprPath)) {
        $errors.Add("[$name] missing digital_twin.xpr")
        continue
    }

    $xprText = [IO.File]::ReadAllText($xprPath)
    try {
        [xml]$null = $xprText
    }
    catch {
        $errors.Add("[$name] invalid XPR XML: $($_.Exception.Message)")
        continue
    }

    if ($xprText.Contains('sources_1/new/') -or $xprText.Contains('rtl_full')) {
        $errors.Add("[$name] XPR contains a retired source-tree path")
    }
    if ($xprText.Contains('_archive_restore_only')) {
        $errors.Add("[$name] active XPR references the restore-only archive")
    }

    $referencedFiles = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $matches = [Regex]::Matches($xprText, '<File Path="([^"]+)"')
    foreach ($match in $matches) {
        $xprFile = $match.Groups[1].Value
        $resolved = $xprFile.Replace('$PSRCDIR', $sourceDir).Replace('$PPRDIR', $projectDir)
        if ($resolved.Contains('$')) {
            $errors.Add("[$name] unresolved XPR variable: $xprFile")
            continue
        }
        $resolved = [IO.Path]::GetFullPath($resolved.Replace('/', [IO.Path]::DirectorySeparatorChar))
        $null = $referencedFiles.Add($resolved)
        if (-not (Test-Path -LiteralPath $resolved)) {
            $errors.Add("[$name] missing XPR file: $xprFile")
        }
    }

    $unreferencedRtl = @(
        Get-ChildItem -LiteralPath $rtlDir -Recurse -File |
            Where-Object { $_.Extension -in @('.v', '.sv', '.vh') -and -not $referencedFiles.Contains($_.FullName) }
    )
    foreach ($file in $unreferencedRtl) {
        $relative = $file.FullName.Substring($projectDir.Length + 1)
        $errors.Add("[$name] RTL is not listed in XPR: $relative")
    }

    Write-Host "[$name] XML valid; $($matches.Count) XPR file references; $(@(Get-ChildItem -LiteralPath $rtlDir -Recurse -File).Count) RTL files"
}

$archiveRoot = Join-Path $repoRoot '_archive_restore_only'
$snapshotRoot = Join-Path $archiveRoot 'source-98f3aab'
$manifestPath = Join-Path $archiveRoot 'SHA256SUMS-source-98f3aab.txt'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    $errors.Add('[archive] missing SHA-256 manifest')
}
else {
    $manifestLines = @(Get-Content -LiteralPath $manifestPath -Encoding UTF8 | Where-Object { $_.Trim() })
    $snapshotFiles = @(Get-ChildItem -LiteralPath $snapshotRoot -Recurse -File)
    if ($manifestLines.Count -ne $snapshotFiles.Count) {
        $errors.Add("[archive] manifest has $($manifestLines.Count) entries but snapshot has $($snapshotFiles.Count) files")
    }
    foreach ($line in $manifestLines) {
        if ($line -notmatch '^([0-9a-f]{64})  (.+)$') {
            $errors.Add("[archive] invalid manifest line: $line")
            continue
        }
        $expectedHash = $Matches[1]
        $relative = $Matches[2].Replace('/', [IO.Path]::DirectorySeparatorChar)
        $filePath = [IO.Path]::GetFullPath((Join-Path $archiveRoot $relative))
        $archivePrefix = $archiveRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        if (-not $filePath.StartsWith($archivePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $errors.Add("[archive] manifest path escapes archive: $relative")
            continue
        }
        if (-not (Test-Path -LiteralPath $filePath)) {
            $errors.Add("[archive] missing snapshot file: $relative")
            continue
        }
        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $filePath).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            $errors.Add("[archive] hash mismatch: $relative")
        }
    }
    Write-Host "[archive] $($manifestLines.Count) snapshot files checked against SHA-256 manifest"
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host 'Active Vivado references and restore-only archive are consistent.'
