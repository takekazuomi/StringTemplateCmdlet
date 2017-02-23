Write-Host (Get-Location)

Import-Module "$PSScriptRoot/azure-ssh" -Force

Set-StrictMode -Version Latest

Describe "vmaccess" {
    Context "Set-AzVMResetPassword" {
        $password =  -join (@(33)+(35..37)+(40..59)+@(61)+(63..91)+(93..122)+@(124)+@(126) | Get-Random -Count 50 | %{[char]$_})
        It "Change Password Validation Only" {
            $result = Set-AzVMUserCredentials -ValidationOnly -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi" -Password $password -Verbose
            $result
        }

        It "Change Password" {
            $result = Set-AzVMUserCredentials -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi" -Password $password -Verbose
            $result
        }

        It "new user and key auth" {
            $pubid = Get-Content (join-path (split-path (Get-SshPath) -parent) "id_rsa.pub")
            $result = Set-AzVMUserCredentials -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi" -SshKey "$pubid" -Verbose
            $result
        }
    }
}


# 
# using namespace System.Web;
#(0..100) | %{$s=-join (@(33)+(35..37)+(40..59)+@(61)+(63..91)+(93..122)+@(124)+@(126) | Get-Random -Count 50 | %{[char]$_});[HttpUtility]::JavaScriptStringEncode($s, $true)}

Describe "customscript" -Tag "customscript" {
    Context "Set-AzVMCustomScript" {
        It -Skip "Uris Validation Only" {
            $result = Set-AzVMCustomScript -ValidationOnly -ResourceGroupName kinmugicos02 -VMName kinmugicos02 -FileUris "http://foo","http://boo", "http://woo" -CommandToExecute "bash setup.sh" -Verbose
            $result
        }

        It "File Validation Only" {
            $param = @{
                ValidationOnly=$true
                ResourceGroupName="kinmugicos02"
                VMName="kinmugicos02"
                Files = @(".\azure-ssh.Tests.ps1")
                StorageAccountName = "kinmugifile02"
                ContainerName = "runtime"
                CommandToExecute = "bash setup.sh"
                Verbose=$true
            }
            $result = Set-AzVMCustomScript @param
            $result
        }
    }
}
