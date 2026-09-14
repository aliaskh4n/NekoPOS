# Установка Neko POS на Windows — скачивает актуальный релиз, кладёт в
# %LOCALAPPDATA%\NekoPOS и создаёт ярлык в меню «Пуск».
$ErrorActionPreference = "Stop"

$Repo = "aliaskh4n/NekoPOS"
$Asset = "pos-windows-amd64.exe"
$InstallDir = Join-Path $env:LOCALAPPDATA "NekoPOS"

$Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
$Tag = $Release.tag_name
Write-Host "Скачиваю Neko POS $Tag..."

$Tmp = Join-Path $env:TEMP ([System.Guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null
try {
    $ExePath = Join-Path $Tmp $Asset
    Invoke-WebRequest -Uri "https://github.com/$Repo/releases/download/$Tag/$Asset" -OutFile $ExePath

    $ShaUrl = "https://github.com/$Repo/releases/download/$Tag/$Asset.sha256"
    try {
        $ShaPath = Join-Path $Tmp "$Asset.sha256"
        Invoke-WebRequest -Uri $ShaUrl -OutFile $ShaPath
        $Expected = (Get-Content $ShaPath).Split(" ")[0].Trim().ToLower()
        $Actual = (Get-FileHash $ExePath -Algorithm SHA256).Hash.ToLower()
        if ($Expected -ne $Actual) {
            throw "Контрольная сумма не совпала — файл повреждён при скачивании, попробуйте ещё раз."
        }
    } catch {
        Write-Warning "Не удалось проверить контрольную сумму: $_"
    }

    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    $Dest = Join-Path $InstallDir "NekoPOS.exe"
    Copy-Item $ExePath $Dest -Force

    $StartMenu = [Environment]::GetFolderPath("Programs")
    $Shortcut = Join-Path $StartMenu "Neko POS.lnk"
    $Shell = New-Object -ComObject WScript.Shell
    $Link = $Shell.CreateShortcut($Shortcut)
    $Link.TargetPath = $Dest
    $Link.WorkingDirectory = $InstallDir
    $Link.Save()

    Write-Host "Готово: $Dest (ярлык — в меню Пуск, «Neko POS»)"
    Start-Process $Dest
} finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
