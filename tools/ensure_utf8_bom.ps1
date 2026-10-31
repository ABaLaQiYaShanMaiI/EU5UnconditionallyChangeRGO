param(
    [Parameter(Mandatory = $true)][string[]]$Path
)

$ErrorActionPreference = 'Stop'
$utf8Bom = New-Object System.Text.UTF8Encoding($true)

foreach ($p in $Path) {
    $item = Get-Item -LiteralPath $p -ErrorAction Stop
    if ($item.PSIsContainer) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($item.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host ("[BOM ok]   " + $item.Name)
        continue
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    [System.IO.File]::WriteAllText($item.FullName, $text, $utf8Bom)
    Write-Host ("[BOM add]  " + $item.Name)
}
