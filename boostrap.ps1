

param(
    [switch] $Ask
)

$ErrorActionPreference = "stop"

$PowerShellURL                  = "https://github.com/PowerShell/PowerShell/releases/download/v7.2.6/PowerShell-7.2.6-win-x64.msi"
$GitURL                         ="https://github.com/git-for-windows/git/releases/download/v2.32.0.windows.1/Git-2.32.0-64-bit.exe"


function infomessage($message){
    write-host $message
}

function ask($message){
    if($ForceYes -eq $true){ return $true}
    write-host $message -NoNewline -ForegroundColor Yellow
    $resp = read-host " [Y]es/[N]o/Yes to [A]ll "
    if($resp.tolower() -eq "y"){
        return $true
    }else{
        if($resp.tolower() -eq "a"){
          $global:ForceYes = $true
          return $true
        }else{
          return $false
        }
    }
}

Function Exec-ShowOutput
{
    param(
        [Parameter(Mandatory = $true)]
        [String] $binary,

        [Parameter(Mandatory = $false)]
        [Alias('args')]
        [String] $binaryargs,

        [Parameter(Mandatory = $false)]
        [switch] $noThrow
    )

    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $binary
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    if ($binaryargs)
    {
        $pinfo.Arguments = "$binaryargs"
    }
    $pinfo.CreateNoWindow = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()

    if ($p.ExitCode -ne 0)
    {
        if (-not $noThrow)
        {
            Write-Host $stderr -ForegroundColor Red
            throw $stderr
        }
    }

    [hashtable]$Return = @{}
    $Return.ReturnCode = [int] $p.ExitCode
    $Return.stdErr = [string] $stderr
    $Return.stdOut = [string] $stdout
    return $Return
}


   
    if(!($ask){
		$ForceYes = $true
	}

    Write-Host " ============================================================================="
    Write-Host " Bootstrap Dependencies Installer "
    Write-Host " ============================================================================="
    Write-Host " "


    
        ##############################################################
        # PowerShell
        ##############################################################
        infomessage " > Checking PowerShell Version..."
        if($PSVersionTable.PSVersion.major -lt 7){
            infomessage " - Need PowerShell v7+ , found v$($PSVersionTable.PSVersion)"
            if(Ask(" - Add Powershell 7 ?")){
                Invoke-WebRequest -Uri $PowerShellURL -OutFile "$($env:TEMP)\ps7-install.msi" -ContentType binary
                infomessage " - Installing Powershell 7.."
                $webDeployInstallerFilePath = "$($env:TEMP)\ps7-install.msi"
                $arguments = "/i `"$webDeployInstallerFilePath`" /quiet"
                Start-Process msiexec.exe -ArgumentList $arguments -Wait
                infomessage " - Installing Powershell 7.. - DONE."
            }
        } 

           ##############################################################
        # Git for Windows
        ##############################################################
        try
        {
            infomessage " > Checking Git for Windows is installed..."
            $VersionOutput = Exec-ShowOutput -binary "git.exe" -args "--version"
            infomessage "  - Found Git installation: $($VersionOutput.stdOut.Trim())"
        }
        catch
        {
            infomessage "  - Git not installed"
            if(Ask(" - Add Git Client ?")){
                try
                {
                    infomessage "  - Downloading Git"
                    Invoke-WebRequest -Uri $gitURL -OutFile "$env:TEMP\git-install.exe" # -ContentType binary
                    infomessage "  - Git downloaded successfully"
                }
                catch
                {
                    infomessage "  - Problem downloading Git. ERROR below:" -ForegroundColor Red
                    if ($_.ErrorDetails.Message)
                    {
                        infomessage $_.ErrorDetails.Message -ForegroundColor Red
                    }
                    else
                    {
                        infomessage $_.Exception.Message -ForegroundColor Red
                    }
                    infomessage "  - Try download and install the file manually: $GitURL"
                    $FailedInstalls += 'Git'
                }

                if ($FailedInstalls -notcontains 'Git')
                {
                    try
                    {
                        infomessage "  - Installing Git"
                        Exec-ShowOutput -binary "$env:TEMP\git-install.exe" -args "/silent /loadinf=.\git.inf"
                        infomessage "  - Git installed OK."
                    }
                    catch
                    {
                        infomessage "  - Git failed to install. ERROR below:" -ForegroundColor Red
                        infomessage $_.Exception.Message -ForegroundColor Red
                        $FailedInstalls += 'Git'
                    }
                }
            }
        }


    write-host " #################################################################### "
    write-host " # Now CLOSE this command prompt, and re-open to update paths!      # "
    write-host " #################################################################### "
    
    cd \
    & "C:\Program Files\PowerShell\7\pwsh.exe" -WorkingDirectory c:\ -command "git clone https://github.com/hpemart/com-cloud"

