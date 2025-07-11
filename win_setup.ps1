$mainFunction = 
{
    $mypath = $MyInvocation.MyCommand.Path
    Write-Output "Path of the script: $mypath"
    Write-Output "Args for script: $Args"

    GetLatestWinGet 

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $dscUri = "https://raw.githubusercontent.com/pumacks/winconfig/main/"
    $dscGenSoftware = "general_software.yml";
    $dscGamingSoftware = "gaming_software.yml";
    $dscWinSettings = "general_settings.yml";
    $dscDev = "dev_software.yml";

    $dscGamingUri = $dscUri + $dscGamingSoftware;
    $dscGenSoftwareUri = $dscUri + $dscGenSoftware 
    $dscDevUri = $dscUri + $dscDev
    $dscWinSettingsUri = $dscUri + $dscWinSettings

    # amazing, we can now run WinGet get fun stuff
    if (!$isAdmin)
    {
        # Shoulder tap terminal to it gets registered moving foward
        Start-Process shell:AppsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App

        winget configuration -f $dscGenSoftwareUri 
   
        # restarting for Admin now
        Start-Process PowerShell -wait -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$mypath' $Args;`"";
        exit;
    }
    else 
    {
        # starting windows settings configuration
        Write-Host "Start: Windows settings configuration"
        winget configuration -f $dscWinSettingsUri
        Write-Host "Done: Windows settings configuration"

        # staring dev workload
        Write-Host "Start: Dev software install"
        winget configuration -f $dscDevUri 
        Write-Host "Done: Dev software install"

        # starting general software
        Write-Host "Start: General software install"
        winget configuration -f $dscGenSoftwareUri 
        Write-Host "Done: General software install"
        
        # starting gaming software
        $installGaming = Read-Host "Install gaming software? (steam, discord and more) (y/n)"

        if ($installGaming -eq "y") {
            Write-Host "Start gaming software install"
            winget configuration -f $dscGamingUri 
            Write-Host "Done gaming software install"
        } else {
            Write-Host "skipping gaming software install"
        }
    }
}

function GetLatestWinGet
{
    # forcing WinGet to be installed
    $isWinGetRecent = (winget -v).Trim('v').TrimEnd("-preview").split('.')

    # turning off progress bar to make invoke WebRequest fast
    $ProgressPreference = 'SilentlyContinue'

    if(!(($isWinGetRecent[0] -gt 1) -or ($isWinGetRecent[0] -ge 1 -and $isWinGetRecent[1] -ge 6))) # WinGet is greater than v1 or v1.6 or higher
    {
       $paths = "Microsoft.VCLibs.x64.14.00.Desktop.appx", "Microsoft.UI.Xaml.2.8.x64.appx", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
       $uris = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx", "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx", "https://aka.ms/getwinget"
       Write-Host "Downloading WinGet and its dependencies..."

       for ($i = 0; $i -lt $uris.Length; $i++) {
           $filePath = $paths[$i]
           $fileUri = $uris[$i]
           Write-Host "Downloading: ($filePath) from $fileUri"
           Invoke-WebRequest -Uri $fileUri -OutFile $filePath
       }

       Write-Host "Installing WinGet and its dependencies..."
   
       foreach($filePath in $paths)
       {
           Write-Host "Installing: ($filePath)"
           Add-AppxPackage $filePath
       }

       Write-Host "Verifying Version number of WinGet"
       winget -v

       Write-Host "Cleaning up"
       foreach($filePath in $paths)
       {
          if (Test-Path $filePath) 
          {
             Write-Host "Deleting: ($filePath)"
             Remove-Item $filePath -verbose
          } 
          else
          {
             Write-Error "Path doesn't exits: ($filePath)"
          }
       }
    }
    else {
       Write-Host "WinGet in decent state, moving to executing DSC"
    }
}

& $mainFunction