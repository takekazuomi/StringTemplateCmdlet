Import-Module "$PSScriptRoot/../azure-ssh" -Force

Set-StrictMode -Version Latest

Describe "vmaccess" {
    Context "Parameters" {
        It "Change Password Validation Only" {
            $result = Set-AzVMUserCredentials -ValidationOnly -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi" -Password "0575yR18]~t7T997Epbp#!DujDWUTW" -Verbose
            $result
        }

        It "Change Password" {
            $result = Set-AzVMUserCredentials -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi" -Password "0575yR18]~t7T997Epbp#!DujDWUTW" -Verbose
            $result
        }

        It "new user and key auth" {
            $pubid = Get-Content (join-path (split-path (Get-SshPath) -parent) "id_rsa.pub")
            $result = Set-AzVMUserCredentials -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi3" -SshKey "$pubid" -Verbose
            $result
        }
    }
}