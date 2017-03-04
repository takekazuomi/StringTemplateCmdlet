using namespace System.Collections.Generic;

function getSshConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$RsourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [string]$IdentityFile="~/.sshd/id_rsa",
        [string]$PasswordAuthentication="no"
    )

    # https://github.com/Azure/azure-powershell/blob/master/src/ResourceManager/Compute/Commands.Compute/RemoteDesktop/GetAzureRemoteDesktopFileCommand.cs#L99

    $vm = Get-AzureRmVM -ResourceGroupName $RsourceGroupName -Name $Name
    $nicId = ($vm.NetworkProfile.NetworkInterfaces | Select-Object -First 1).Id

    $nic = Get-AzureRmResource -ResourceId $nicId

    $pipId = $nic.Properties.ipConfigurations | Select-Object -First 1 | ?{$_.properties.publicIPAddress} | %{$_.properties.publicIPAddress.Id}
    if($pipId)
    {
        $pip = Get-AzureRmResource -ResourceId $pipId | %{$_.Properties | Select-Object -First 1}
        $ipaddress = $pip.ipAddress
        $fqdn = $pip.dnsSettings.fqdn
    }
    else {
        $ipcId = $nic.Properties.ipConfigurations | Select-Object -First 1 | %{$_.Id}
        $ipc = Get-AzureRmResource -ResourceId $ipcId -ApiVersion 2016-12-01 | %{$_.Properties | Select-Object -First 1}
        $ipaddress = $ipc.privateIPAddress
    }

    $config = @{
        Host = $Name
        Properties = [ordered]@{
            HostName = (?? $fqdn $ipaddress $ipaddress)
            PasswordAuthentication = $PasswordAuthentication
            IdentityFile = $IdentityFile
            LogLevel = "FATAL"
        }
    }
    $config
}

function Get-AzSshConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [string]$IdentityFile="~/.sshd/id_rsa",
        [string]$PasswordAuthentication="no"
    )

    $config = getSshConfig $ResourceGroupName $Name $IdentityFile $PasswordAuthentication

    $result = $config | Convert-StTemplate -GroupPath $PSScriptRoot/st/sshconfig.stg -TemplateName host
    $result
}

function Get-AzSshJumpboxConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        #[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM,
        [object]$VM,
        [string]$IdentityFile="~/.sshd/id_rsa",
        [ValidateSet("yes","no")]
        [string]$PasswordAuthentication="no"
    )

    begin {
        $config = getSshConfig $ResourceGroupName $Name $IdentityFile $PasswordAuthentication
        $localPort=8000
        $localForward = [list[hashtable]]@()
        $localForwardHost = [list[hashtable]]@()
    }

    Process {
        if($VM.Name -ne $name) {
            $nicId = ($vm.NetworkProfile.NetworkInterfaces | Select-Object -First 1).Id
            $nic = Get-AzureRmResource -ResourceId $nicId
            $ipcId = $nic.Properties.ipConfigurations | Select-Object -First 1 | %{$_.Id}
            $ipc = Get-AzureRmResource -ResourceId $ipcId -ApiVersion 2016-12-01 | %{$_.Properties | Select-Object -First 1}
            $ipaddress = $ipc.privateIPAddress
            # LocalForward 13389 10.92.0.5:3389 # vmname
            $localPort++

            $vmName = $VM.Name
            $remotePort = ?: {$VM.StorageProfile.OsDisk.OsType -eq "Windows"} {
                Write-Host $vmName
                Get-AzSshRemoteDesktopFile -Name $vmName -HostName "localhost" -Port $localPort -Path $Path | Out-Null
                3389
            } {
                # add ssh setting
                $config = @{
                    Host = $vmName
                    Properties = [ordered]@{
                        HostName = "localhost"
                        Port = ${localPort}
                        PasswordAuthentication = $PasswordAuthentication
                        IdentityFile = $IdentityFile
                    }
                }
                $localForwardHost.Add($config)
                22
            }
            $localForward.Add(@{value="${localPort} ${ipaddress}:${remotePort}"; comment="$(${VM}.Name)"})
        }
    }

    End {
        $config.Properties["LocalForward"]=$localForward
        $hosts = [list[hashtable]]@()
        $hosts.Add($config)
        $hosts.AddRange($localForwardHost)

        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/sshconfig.stg -TemplateName host -config  $hosts
        $result | Out-File -Encoding ascii -FilePath (Join-Path $Path "ssh_${Name}.config") -Force
    }
}

function Get-AzSshRemoteDesktopFile{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$HostName,
        [Parameter(Mandatory=$true)]
        [string]$Port,
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $outfile = ?: {$Path -match "\.rdp$"} {$Path} {Join-Path $Path "$Name.rdp"}
    Write-Host $outfile
    Convert-StTemplate -GroupPath $PSScriptRoot/st/rdpfile.stg -TemplateName rdpfile -host $HostName -port $Port | Out-File -Encoding ascii -FilePath $outfile -Force
}

# install your public key in a remote machine's authorized_keys
function Copy-SshId {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]$HostName,
        [Parameter(Position=1,Mandatory=$true)]
        [string]$User,
        [Parameter(Position=2, HelpMessage="your public key")]
        [string]$IdentityFile
    )

    $IdentityFile = ?? {$IdentityFile} { join-path (split-path (Get-SshPath) -Parent) "id_rsa.pub"}
    $id = (Get-Content -Raw $IdentityFile) -replace "`n", ""
    Write-Verbose $IdentityFile
    $copycmd =
@"
install -m 700 -d ~/.ssh
echo `"$id`" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
"@ -replace "`r", ""

    Write-Verbose $copycmd
    ssh $User@$HostName $copycmd
}
