using namespace System.Collections.Generic;
using namespace Microsoft.Azure.Commands.Compute.Models;

function getSshConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$RsourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [string]$IdentityFile="~/.sshd/id_rsa"
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
            ServerAliveInterval = 60
            UserKnownHostsFile="/dev/null"
            StrictHostKeyChecking = "no"
            PasswordAuthentication = "no"
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
        [string]$IdentityFile="~/.sshd/id_rsa"
    )

    $config = getSshConfig $ResourceGroupName $Name $IdentityFile

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
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [PSVirtualMachine]$VM,
        [string]$IdentityFile="~/.sshd/id_rsa"
    )

    begin {
        $config = getSshConfig $ResourceGroupName $Name $IdentityFile
        $localPort=8000
        $localForward = [list[hashtable]]@()
    }
    
    Process {
        if($VM.Name -ne $name) {
            $nicId = ($vm.NetworkProfile.NetworkInterfaces | Select-Object -First 1).Id
            $nic = Get-AzureRmResource -ResourceId $nicId
            $ipcId = $nic.Properties.ipConfigurations | Select-Object -First 1 | %{$_.Id}
            $ipc = Get-AzureRmResource -ResourceId $ipcId -ApiVersion 2016-12-01 | %{$_.Properties | Select-Object -First 1}
            $ipaddress = $ipc.privateIPAddress
            # LocalForward 13389 10.92.0.5:3389 # vmname
            $remotePort = ?: {$VM.StorageProfile.OsDisk.OsType -eq "Windows"} {3389} {22}
            $localPort++
            $localForward.Add(@{value="${localPort} ${ipaddress}:${remotePort}"; comment="$(${VM}.Name)"})
        }
    }

    End {
        $config.Properties["LocalForward"]=$localForward 
        $result = $config | Convert-StTemplate -GroupPath $PSScriptRoot/st/sshconfig.stg -TemplateName host
        $result
    }
}
