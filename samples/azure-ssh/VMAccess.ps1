using namespace System.Collections.Generic;

function deployResourceGroupDeployment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$VMName,
        [Parameter(Mandatory=$true)]
        [string]$Template,
        [switch]$ValidationOnly=$false
    )

    $verbose = ?? $PSBoundParameters.Verbose $false

    $deployFile = New-TemporaryFile 
    try{
        Set-Content -Path $deployFile -Value $Template -Encoding Ascii
        if($ValidationOnly){
            Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $deployFile -Verbose:$verbose
        }
        else {
            New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $deployFile -Verbose:$verbose
        }
        $result
    }
    finally{
        Remove-Item $deployFile -Force
    }
}

function buildConfig {
    param(
        [string]$VMName
    )
    [ordered]@{
        name = "$VMName/enablevmaccess"
        apiVersion = "2016-03-30"
        location = "[resourceGroup().location]"
        publisher = "Microsoft.OSTCExtensions"
        type = "VMAccessForLinux"
        typeHandlerVersion= "1.4"
        autoUpgradeMinorVersion = $true
        settings = [ordered]@{
        }
        protectedSettings = [ordered]@{
        }
    }
}

function Set-AzVMUserCredentials {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$VMName,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$UserName,
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Password,
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$SshKey,
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [datetime]$Expiration,
        [switch]$ValidationOnly=$false
    )
    $verbose = ?? $PSBoundParameters.Verbose $false

    if(!$Password -and !$Sshkey) {Write-Error -Message "Either -Password or -SshKey is mandatory"}

    $config = buildConfig $VMName

    if ($UserName) {$config.protectedSettings.Add("username", $UserName)}
    if ($Password) {$config.protectedSettings.Add("password", $Password)}
    if ($Sshkey) {$config.protectedSettings.Add("ssh_key", $Sshkey)}
    if ($Expiration) {$config.protectedSettings.Add("expiration", $Expiration)}

    $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/vmaccess.stg -TemplateName vmaccess -config $config -Verbose:$verbose 
    Write-Verbose $result -Verbose:$verbose

    deployResourceGroupDeployment $ResourceGroupName $VMName $result -ValidationOnly:$ValidationOnly -Verbose:$verbose
}

function Remove-AzVMUser {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$VMName,
        [switch]$ValidationOnly=$false,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$UserName
    )

    begin {
        $verbose = ?? $PSBoundParameters.Verbose $false
    }

    process {
        $config = buildConfig $VMName
        $config.protectedSettings.Add("remove_user", $UserName)

        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/vmaccess.stg -TemplateName vmaccess -config $config -Verbose:$verbose 
        Write-Verbose $result -Verbose:$verbose

        deployResourceGroupDeployment $ResourceGroupName $VMName $result -ValidationOnly:$ValidationOnly -Verbose:$verbose
    }

    end{
    }
}

function Reset-AzVMSshConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$VMName,
        [switch]$ValidationOnly=$false
    )

    begin {
        $verbose = ?? $PSBoundParameters.Verbose $false
    }

    process {
        $config = buildConfig $VMName
        $config.protectedSettings.Add("reset_ssh", $true)

        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/vmaccess.stg -TemplateName vmaccess -config $config -Verbose:$verbose 
        Write-Verbose $result -Verbose:$verbose

        deployResourceGroupDeployment $ResourceGroupName $VMName $result -ValidationOnly:$ValidationOnly -Verbose:$verbose
   }

    end {
    }
}


function Reset-AzVMSshConfig {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$VMName,
        [switch]$ValidationOnly=$false
    )

    begin {
        $verbose = ?? $PSBoundParameters.Verbose $false
    }

    process {
        $config = buildConfig $VMName
        $config.protectedSettings.Add("reset_ssh", $true)

        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/vmaccess.stg -TemplateName vmaccess -config $config -Verbose:$verbose 
        Write-Verbose $result -Verbose:$verbose

        deployResourceGroupDeployment $ResourceGroupName $VMName $result -ValidationOnly:$ValidationOnly -Verbose:$verbose
   }

    end {
    }
}

function Check-AzVMDisk {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$VMName,
        [switch]$ValidationOnly=$false
    )

    begin {
        $verbose = ?? $PSBoundParameters.Verbose $false
    }

    process {
        # check_disk and repair_disk looks  is readed from public_settings
        # https://github.com/takekazuomi/azure-linux-extensions/blob/master/VMAccess/vmaccess.py#L405
        # missing information in following link
        # https://github.com/Azure/azure-linux-extensions/tree/master/VMAccess#23-using-arm-template 

        $config = buildConfig $VMName
        $config.protectedSettings.Add("check_disk", $true)

        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/vmaccess.stg -TemplateName vmaccess -config $config -Verbose:$verbose 
        Write-Verbose $result -Verbose:$verbose

        deployResourceGroupDeployment $ResourceGroupName $VMName $result -ValidationOnly:$ValidationOnly -Verbose:$verbose
   }

    end {
    }
}

function Repair-AzVMDisk {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$VMName,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$DiskName,
        [switch]$ValidationOnly=$false
    )

    begin {
        $verbose = ?? $PSBoundParameters.Verbose $false
    }

    process {
        $config = buildConfig $VMName
        # repair_disk can only specify one disk. may be fix boot disk and repair other disk after boot it.
        $config.protectedSettings.Add("repair_disk", $true)
        $config.protectedSettings.Add("disk_name", $DiskName)

        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/vmaccess.stg -TemplateName vmaccess -config $config -Verbose:$verbose 
        Write-Verbose $result -Verbose:$verbose

        deployResourceGroupDeployment $ResourceGroupName $VMName $result -ValidationOnly:$ValidationOnly -Verbose:$verbose
    }

    end {
    }
}

<#
VMAccess Extension 2.3. Using ARM Template
https://github.com/Azure/azure-linux-extensions/tree/master/VMAccess#23-using-arm-template 

3.1 Resetting the password
{
  "username": "currentusername",
  "password": "newpassword"
}

3.2 Resetting the SSH key
{ 
  "username": "currentusername", 
  "ssh_key": "contentofsshkey"
}

3.3 Resetting the password and the SSH key
{
  "username": "currentusername",
  "ssh_key": "contentofsshkey",
  "password": "newpassword",
}

3.4 Creating a new sudo user account with the password
{
  "username": "newusername",
  "password": "newpassword"
}

3.4.1 Creating a new sudo user account with a password and expiration date.
{
  "username": "newusername",
  "password": "newpassword",
  "expiration": "2016-12-31"
}

3.5 Creating a new sudo user account with the SSH key
{
  "username": "newusername",
  "ssh_key": "contentofsshkey"
}

3.5.1 Creating a new sudo user account with the SSH key
{
  "username": "newusername",
  "ssh_key": "contentofsshkey",
  "expiration": "2016-12-31"
}

3.6 Resetting the SSH configuration
{
  "reset_ssh": true
}

3.7 Removing an existing user
{
  "remove_user": "usertoberemoveed",
}

3.8 Checking added disks on VM
{
    "check_disk": "true"
}

3.9 Fix added disks on a VM
{
    "repair_disk": "true",
    "disk_name": "userdisktofix"
}

#>
