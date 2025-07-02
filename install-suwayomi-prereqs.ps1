# 1️⃣ Self-elevate if not Admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2️⃣ Ensure in-process execution policy
if ((Get-ExecutionPolicy -Scope Process) -ne 'Bypass') {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

# 3️⃣ Install Chocolatey if needed
if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey…"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Write-Error "Chocolatey install failed!"
        exit 1
    }
    Write-Host "✅ Chocolatey installed."
} else {
    Write-Host "✅ Chocolatey already present."
}
choco feature enable -n=allowGlobalConfirmation

# 4️⃣ Packages to install
$packages = @{
    temurin21 = ''; 'nodejs' = '--version=22.12.0'; yarn = ''; nvm = ''
}

foreach ($pkg in $packages.Keys) {
    $opts = $packages[$pkg]
    Write-Host "Installing $pkg…"
    choco install $pkg $opts -y
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$pkg may have failed to install (exit code $LASTEXITCODE)."
    }
}

# 5️⃣ Done
Write-Host "`n🎉 All prerequisites attempted."
Write-Host "👉 Please close and reopen your terminal (or VS Code)."
Write-Host "👉 Then verify by running:"
Write-Host "     java -version"
Write-Host "     node --version"
Write-Host "     yarn --version"
Write-Host "👉 If using nvm: run 'nvm install 22.12.0; nvm use 22.12.0'"
