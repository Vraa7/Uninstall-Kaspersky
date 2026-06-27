$klUsername = ""
$klPassword = ""

$cleanerSource = "\\isi_server\isi_share\cleaner.exe"
$cleanerLocal  = "C:\Windows\Temp\cleaner.exe"

# ---------------------------------------------------------------

function Write-Info    { param($msg) Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Fail    { param($msg) Write-Host "[-] $msg" -ForegroundColor Red }
function Write-Done    { param($msg) Write-Host "[v] $msg" -ForegroundColor Yellow }
function Write-Title   { param($msg) Write-Host $msg -ForegroundColor White }

$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# ==============================================================
#  PROCESS 1 - Uninstall Kaspersky Endpoint Security
# ==============================================================

Write-Host ""
Write-Title "============================================================"
Write-Title "   PROCESS 1 : Kaspersky Endpoint Security Uninstaller     "
Write-Title "============================================================"
Write-Host ""

Write-Info "Mencari GUID Kaspersky Endpoint Security di registry..."

$payloadKES = Get-ItemProperty -Path $registryPaths -ErrorAction SilentlyContinue |
              Where-Object { $_.DisplayName -like "*Kaspersky Endpoint Security*" }

if ($null -eq $payloadKES -or $payloadKES.Count -eq 0) {

    Write-Fail "GUID Tidak Ditemukan"
    Write-Host ""

} else {

    $guidKES = $payloadKES.PSChildName
    if ($guidKES -is [array]) {
        Write-Info "Ditemukan $($guidKES.Count) entri, menggunakan entri pertama."
        $guidKES = $guidKES[0]
    }

    Write-Success "GUID Ditemukan serta tuliskan GUID nya : $guidKES"
    Write-Host ""

    Write-Info "Menjalankan proses uninstall Kaspersky Endpoint Security..."

    $process1 = Start-Process -FilePath "msiexec.exe" `
                              -ArgumentList "/x $guidKES KLLOGIN=$klUsername KLPASSWD=$klPassword /qn" `
                              -Wait `
                              -PassThru

    if ($process1.ExitCode -eq 0) {
        Write-Success "Proses uninstall selesai. (Exit Code: 0)"
    } else {
        Write-Fail "Proses selesai dengan Exit Code: $($process1.ExitCode)"
    }

    Write-Host ""
}

Write-Done "Proses Uninstall Kaspersky Endpoint Security Telah Selesai"
Write-Host ""

# ==============================================================
#  PROCESS 2 - Uninstall Kaspersky Security Center Network Agent
# ==============================================================

Write-Host ""
Write-Title "============================================================"
Write-Title "   PROCESS 2 : KSC Network Agent Uninstaller               "
Write-Title "============================================================"
Write-Host ""

Write-Info "Menyalin cleaner.exe dari network share ke lokal..."

if (-not (Test-Path $cleanerSource)) {
    Write-Fail "cleaner.exe tidak ditemukan di: $cleanerSource"
    Write-Fail "Pastikan network share dapat diakses dan path sudah benar."
    exit 1
}

try {
    Copy-Item -Path $cleanerSource -Destination $cleanerLocal -Force -ErrorAction Stop
    Write-Success "cleaner.exe berhasil disalin ke: $cleanerLocal"
} catch {
    Write-Fail "Gagal menyalin cleaner.exe. Error: $_"
    exit 1
}

Write-Host ""

Write-Info "Mencari GUID Kaspersky Security Center Network Agent di registry..."

$payloadNA = Get-ItemProperty -Path $registryPaths -ErrorAction SilentlyContinue |
             Where-Object {
                 $_.DisplayName -like "*Kaspersky Security Center*Network Agent*" -or
                 $_.DisplayName -like "*Kaspersky Network Agent*" -or
                 $_.DisplayName -like "*Network Agent*Kaspersky*"
             }

if ($null -eq $payloadNA -or $payloadNA.Count -eq 0) {

    Write-Fail "GUID Tidak di temukan"
    Write-Host ""

} else {
D
    $guidNA = $payloadNA.PSChildName
    if ($guidNA -is [array]) {
        Write-Info "Ditemukan $($guidNA.Count) entri, menggunakan entri pertama."
        $guidNA = $guidNA[0]
    }

    Write-Success "GUID Ditemukan serta tuliskan GUID nya : $guidNA"
    Write-Host ""

    Write-Info "Menjalankan perintah: cleaner.exe /uc `"$guidNA`""

    $process2 = Start-Process -FilePath $cleanerLocal `
                              -ArgumentList "/uc `"$guidNA`"" `
                              -Wait `
                              -PassThru

    if ($process2.ExitCode -eq 0) {
        Write-Success "Perintah cleaner.exe selesai dijalankan. (Exit Code: 0)"
    } else {
        Write-Fail "Perintah selesai dengan Exit Code: $($process2.ExitCode)"
    }

    Write-Host ""
}

Write-Info "Membersihkan file temporary..."
if (Test-Path $cleanerLocal) {
    Remove-Item -Path $cleanerLocal -Force -ErrorAction SilentlyContinue
    Write-Success "cleaner.exe berhasil dihapus dari lokal."
}

Write-Host ""

Write-Done "Proses Uninstall Kaspersky Security Center Network Agent Telah Selesai"
Write-Host ""

Write-Title "============================================================"
Write-Title "   Selesai - Semua Proses Uninstall Telah Dijalankan       "
Write-Title "============================================================"
Write-Host ""
