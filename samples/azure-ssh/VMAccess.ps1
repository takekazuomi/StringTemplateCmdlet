function Set-AzVMResetPassword {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$VMName,
        [Parameter(Mandatory=$true)]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [string]$Password,
        [switch]$ValidationOnly=$false
    )

    $config = [ordered]@{
        name = "$VMName/enablevmaccess"
        apiVersion = "2016-03-30"
        location = "[resourceGroup().location]"
        publisher = "Microsoft.OSTCExtensions"
        type = "VMAccessForLinux"
        typeHandlerVersion= "1.4"
        autoUpgradeMinorVersion = $true
        protectedSettings = [ordered]@{
            username = $UserName
            password = $Password
        }
    }

    $verbose = ?? $PSBoundParameters.Verbose $false

    $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/vmaccess.stg -TemplateName vmaccess -Verbose:$verbose -config $config
    Write-Debug $result
    $deployFile = New-TemporaryFile 
    try{
        Set-Content -Path $deployFile -Value $result -Encoding Ascii
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
