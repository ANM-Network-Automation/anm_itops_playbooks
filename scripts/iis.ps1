# Ensure script is running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator!"
    exit
}

# Function to check if a reboot is required
function Test-PendingReboot {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
    )

    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    return $false
}

# Check if IIS is installed
$feature = Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole

if ($feature.State -ne "Enabled") {
    Write-Output "IIS is not installed. Installing IIS..."
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart
    Write-Output "IIS installation complete."

    # Check if reboot is required
    if (Test-PendingReboot) {
        Write-Warning "A system reboot is required to complete IIS installation."
        $response = Read-Host "Do you want to reboot now? (Y/N)"
        if ($response -match '^[Yy]') {
            Write-Output "Rebooting system..."
            Restart-Computer
            exit
        } else {
            Write-Warning "You must reboot the system before running this script again to proceed with IIS configuration."
            exit
        }
    }
} else {
    Write-Output "IIS is already installed."
}

Import-Module WebAdministration

# Define the site and virtual directory parameters
$siteName = "Default Web Site"
$vDirName = "http"

# Get current user's Desktop path for the virtual directory
$desktopPath = [Environment]::GetFolderPath("Desktop")
$physicalPath = Join-Path $desktopPath $vDirName

# Ensure Default Web Site exists
$defaultSite = Get-Website -Name $siteName -ErrorAction SilentlyContinue
if (-not $defaultSite) {
    Write-Output "Default Web Site does not exist. Creating it..."
    $rootPath = "C:\inetpub\wwwroot"
    if (-not (Test-Path $rootPath)) {
        New-Item -Path $rootPath -ItemType Directory -Force
    }
    New-Website -Name $siteName -Port 80 -PhysicalPath $rootPath -Force
    Write-Output "Default Web Site created."
} else {
    Write-Output "Default Web Site already exists."
}

# Create physical path if it doesn't exist
if (-not (Test-Path $physicalPath)) {
    Write-Output "Creating physical directory at $physicalPath"
    New-Item -Path $physicalPath -ItemType Directory -Force
}

# Grant IIS_IUSRS read/execute permissions to the folder
$acl = Get-Acl $physicalPath
$permission = "IIS_IUSRS","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
if (-not ($acl.Access | Where-Object { $_.IdentityReference -eq "IIS_IUSRS" })) {
    $acl.AddAccessRule($accessRule)
    Set-Acl $physicalPath $acl
    Write-Output "Granted Read/Execute permissions to IIS_IUSRS for $physicalPath"
}

# Check if virtual directory exists
$vDir = Get-WebVirtualDirectory -Site $siteName -Name $vDirName -ErrorAction SilentlyContinue

if (-not $vDir) {
    Write-Output "Creating virtual directory '$vDirName' under '$siteName'"
    New-WebVirtualDirectory -Site $siteName -Name $vDirName -PhysicalPath $physicalPath
} else {
    Write-Output "Virtual directory '$vDirName' already exists."
}

# Function to test access to the physical folder
function Test-FolderAccess {
    param([string]$Path)
    try {
        $testFile = Join-Path $Path ([GUID]::NewGuid().ToString() + ".tmp")
        New-Item -Path $testFile -ItemType File -Force | Out-Null
        Remove-Item $testFile -Force
        return $true
    } catch {
        return $false
    }
}

# Check if IIS can access the folder
if (-not (Test-FolderAccess -Path $physicalPath)) {
    Write-Warning "IIS cannot access '$physicalPath'. Please provide credentials for the virtual directory."
    $vdCredential = Get-Credential

    # Apply "Connect As" credentials
    Set-WebConfigurationProperty -Filter "system.applicationHost/sites/site[@name='$siteName']/application[@path='/$vDirName']" `
        -Name "userName" -Value $vdCredential.UserName
    Set-WebConfigurationProperty -Filter "system.applicationHost/sites/site[@name='$siteName']/application[@path='/$vDirName']" `
        -Name "password" -Value $vdCredential.GetNetworkCredential().Password

    Write-Output "Configured 'Connect As' credentials for virtual directory."
} else {
    Write-Output "IIS has access to '$physicalPath'. No credentials required."
}

# Enable Directory Browsing
Write-Output "Enabling Directory Browsing for '$vDirName'"
Set-WebConfigurationProperty -Filter "/system.webServer/directoryBrowse" -PSPath "IIS:\Sites\$siteName\$vDirName" -Name "enabled" -Value $true

Write-Output "Script completed successfully!"
