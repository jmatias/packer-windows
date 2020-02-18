param(
    [switch] $Uninstall,
    [switch] $PowershellPackages,
    [switch] $IIS,
    [switch] $VisualStudio,
    [switch] $VisualStudioLegacy,
    [switch] $VsBuildTools,
    [switch] $SqlServer,
    [switch] $JetBrains,
    [switch] $LightTools,
    [switch] $GitAliases,
    [switch] $Virtualization,
    [switch] $All,
    [switch] $NonInteractive
)

$params = $PSBoundParameters

$iisFeatures = @('IIS-WebServerRole', 'IIS-WebServer', 'IIS-CommonHttpFeatures', 'IIS-HttpErrors',
    'IIS-HttpRedirect', 'IIS-ApplicationDevelopment', 'IIS-WebServerManagementTools', 'IIS-ManagementConsole',
    'IIS-ManagementService', 'IIS-ManagementService', 'IIS-ManagementService', 'IIS-ManagementScriptingTools', 'Web-Mgmt-Tools')

$script:ScriptName = $MyInvocation.MyCommand.ToString()
$script:ScriptPath = $MyInvocation.MyCommand.Path

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}



Function Main {

    if (-not (Test-Path $profile)) {
        New-Item -Type File -Path $profile -Force
    }

    if (-not ($IIS -or $VisualStudio -or $VisualStudioLegacy `
                -or $JetBrains -or $LightTools -or $GitAliases -or $Virtualization -or $SqlServer `
                -or $VsBuildTools -or $PowershellPackages)) {
        $All = $true
    }


    Install-PowershellPackages

    if (  $PSVersionTable.PSVersion -gt "6.0") {
        Import-WinModule PendingReboot
        Import-WinModule PSWindowsUpdate
    }
    else {
        Import-Module PendingReboot
        Import-Module PSWindowsUpdate
    }


    if ( -not $Uninstall ) {

        if ($LightTools -or $All) { Install-LightTools }
        if ($JetBrains -or $All) { Install-Jetbrains }
        if ($VisualStudio -or $All) { Install-VisualStudio }
        if ($VisualStudioLegacy -or $All) { Install-VisualStudioLegacy }
        if ($VsBuildTools -or $All) { Install-VsBuildTools }
        if ($SqlServer -or $All) { Install-SqlServer }
        if ($Virtualization -or $All) { Install-Virtualization }
        if ($GitAliases -or $All) { Install-GitAliases }
        if ($IIS -or $All) { Install-IIS }

    }

    if ( $Uninstall) {

        if ($LightTools -or $All) { Uninstall-LightTools }
        if ($JetBrains -or $All) { Uninstall-Jetbrains }
        if ($VisualStudio -or $All) { Uninstall-VisualStudio }
        if ($VisualStudioLegacy -or $All) { Uninstall-VisualStudioLegacy }
        if ($VsBuildTools -or $All) { Uninstall-VsBuildTools }
        if ($SqlServer -or $All) { Uninstall-SqlServer }
        if ($Virtualization -or $All) { Uninstall-Virtualization }
        if ($IIS -or $All) { Uninstall-IIS }
    }

    if ($(Test-PendingReboot).IsRebootPending) {
        "***Reboot is needed.***"
    }

}
Function Install-PowershellPackages {

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Confirm:$false
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module PowerShellGet -Confirm:$false -Force -SkipPublisherCheck


    Install-Module WindowsCompatibility -Confirm:$false -Force
    Install-Module VSSetup -Confirm:$false -Force
    Install-Module PendingReboot
    Install-Module PSWindowsUpdate


    # Chocolatey packages:
    if (-Not(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        "Installing Chocolatey"
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        "`n`n" + 'Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1" -Force' | Add-Content -Path $profile
    }
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1" -Force
    Update-SessionEnvironment

    choco install -y powershell-preview --install-arguments='"ENABLE_PSREMOTING=1"' --packageparameters '"/CleanUpPath"'
    Update-SessionEnvironment

}

function Install-VsBuildTools {

    Reboot-IfRequired
    choco install -y visualstudio2019buildtools -d --package-parameters "--add Microsoft.VisualStudio.Workload.WebBuildTools --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --includeOptional --passive --locale en-US"
    Reboot-IfRequired
}

function Uninstall-VsBuildTools {
    choco uninstall -y visualstudio2019buildtools
}

Function Install-SqlServer {
    choco install -y sql-server-2019 --params="'INSTANCENAME=MSSQLSERVER /ACTION=INSTALL'"
    Reboot-IfRequired
    choco install -y sql-server-management-studio
    Install-Module SqlServer -Confirm:$false -Force

}

Function Uninstall-SqlServer {
    choco uninstall -y sql-server-2019
    choco uninstall -y sql-server-management-studio
}


Function Install-GitAliases {
    Install-Module git-aliases -AllowClobber
}


Function Install-VisualStudio {
    choco install -y visualstudio2019enterprise --package-parameters "--add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --includeOptional --passive --locale en-US"
}

Function Uninstall-VisualStudio {
    choco uninstall -y visualstudio2019enterprise
}

Function Install-VisualStudioLegacy {
    choco install -y visualstudio2012premium -packageParameters "/Features:'VC_MFC_Libraries'"
    Reboot-IfRequired
}

Function UnInstall-VisualStudioLegacy {
    choco uninstall -y visualstudio2012premium
    Reboot-IfRequired
}



Function Install-Jetbrains {
    choco install -y jetbrains-rider
    choco install -y intellijidea-ultimate
}

Function Uninstall-Jetbrains {
    choco uninstall -y jetbrains-rider
    choco uninstall -y intellijidea-ultimate
}

function Install-Virtualization {
    choco install -y terraform
    choco install -y vagrant
    choco install -y packer

}
function Uninstall-Virtualization {
    choco uninstall -y terraform
    choco uninstall -y vagrant
    choco uninstall -y packer
}

Function Install-LightTools {

    choco install -y powershell-preview --install-arguments='"ENABLE_PSREMOTING=1"' --packageparameters '"/CleanUpPath"'
    Reboot-IfRequired
    Update-SessionEnvironment
    choco install -y nodejs
    choco install -y unxUtils
    choco install -y make
    choco install -y nuget.commandline
    choco install -y vscode
    Update-SessionEnvironment
    choco install -y git --params "/GitOnlyOnPath  /NoGuiHereIntegration"
    Reboot-IfRequired
    Update-SessionEnvironment
    choco install -y firefox
    choco install -y procexp
    choco install -y cyberduck
    Update-SessionEnvironment
    choco install -y starship
    choco install -y firacode
    Update-SessionEnvironment
    Reboot-IfRequired

    choco install -y microsoft-windows-terminal
    Update-SessionEnvironment

    $path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $newPath = ($env:Path -replace "C:\\Program Files\\PowerShell\\7-preview\\preview", "C:\Program Files\PowerShell\7-preview")
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

    Update-SessionEnvironment

    if ((Get-Content -Path $profile -Raw ) -notmatch 'starship') {
        Add-Content -Path $profile -Value "`n`nInvoke-Expression (&starship init powershell)"
    }

    Reboot-IfRequired

}

Function Uninstall-LightTools {

    choco uninstall -y powershell-preview
    choco uninstall -y nodejs
    choco uninstall -y unxUtils
    choco uninstall -y make
    choco uninstall -y nuget.commandline
    choco uninstall -y vscode
    choco uninstall -y git
    choco uninstall -y firefox
    choco uninstall -y procexp
    choco uninstall -y cyberduck
    choco uninstall -y starship
    choco uninstall -y firacode

    $path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $newPath = ($env:Path -replace "C:\Program Files\PowerShell\7-preview", "")
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

    $profileContent = (Get-Content -Path $profile -Raw )
    if ( $profileContent -match '.*?starship.*') {
        $match = $Matches.0 -replace "\(", '\('
        $match = $match -replace "\)", '\)'
        $profileContent -replace "$match", ""
    }
    $profileContent | Set-Content -Path $profile

}




Function Install-IIS {

    $featureStates = Get-IISFeatureStates

    $featureStates | Where-Object { $_.State -ne "Enabled" } | Where-Object {
        $iisFeatures.Contains($_.Name)
    }

    $features | ForEach-Object { dism.exe -online -enable-feature -featurename:$($_.Name) -all }

    Install-Module IISAdministration -Confirm:$false -Force

}


Function Uninstall-IIS {


    $featureStates = Get-IISFeatureStates

    $featureStates | Where-Object { $_.State -ne "Disable" } | Where-Object { $iisFeatures.Contains($_.Name) }

    $features | ForEach-Object { dism.exe -online -disable-feature -featurename:$($_.Name) }
    Uninstall-Module IISAdministration -Confirm:$false -Force -ErrorAction SilentlyContinue
}

Function Get-IISFeatureStates {


    $DismOutput = dism.exe -online -get-features | Out-String | Tee-Object -Variable DismOutput

    $regexMatches = $DismOutput | Select-String -Pattern '(?mis)^Feature Name : (?<Name>[-\w]+)\s+?State\s+?:\s+?(?<State>\w+)' -AllMatches

    $featureStates = $regexMatches.Matches | ForEach-Object {
        New-Object psobject -Property @{
            Name  = $_.Groups['Name'].Value
            State = $_.Groups['State'].Value
        }

    } | Where-Object { $iisFeatures.Contains($_.Name) }

    return $featureStates
}


Function Install-Python {
    "Installing Python 3"
    choco install -y python3
    Update-SessionEnvironment
    python -m pip install --upgrade pip
}
Function Uninstall-Python {
    "Installing Python 3"
    python -m pip uninstall pip
    choco uninstall -y python3
    Update-SessionEnvironment
}

$Logfile = "C:\Windows\Temp\win-updates.log"

function LogWrite {
    Param ([string]$logstring)
    $now = Get-Date -format s
    Add-Content $Logfile -value "$now $logstring"
    Write-Output $logstring
}


function Reboot-IfRequired {

    $RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $RegistryEntry = "InstallDevTools"

    if ($(Test-PendingReboot).IsRebootPending) {
        "***Reboot is needed.***"

        $prop = (Get-ItemProperty $RegistryKey).$RegistryEntry
        if (-not $prop) {
            LogWrite "Restart Registry Entry Does Not Exist - Creating It"
            Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File $($script:ScriptPath) $params"

        }
        else {
            LogWrite "Restart Registry Entry Exists Already"
        }
        Restart-Computer
    }
    else {
        "No reboot is required."
        $prop = (Get-ItemProperty $RegistryKey).$RegistryEntry
        if ($prop) {
            LogWrite "Restart Registry Entry Exists - Removing It"
            Remove-ItemProperty -Path $RegistryKey -Name $RegistryEntry -ErrorAction SilentlyContinue
        }
    }
}

Main