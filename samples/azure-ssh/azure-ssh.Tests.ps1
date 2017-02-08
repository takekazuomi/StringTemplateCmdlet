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
