Write-Host (Get-Location)

Import-Module "$PSScriptRoot/azure-ssh" -Force

Set-StrictMode -Version Latest

Describe "vmaccess" {
    Context "Set-AzVMResetPassword" {
#        Mock New-AzureRmResourceGroupDeployment {[CmdletBinding()]param($ResourceGroupName, $TemplateFile)} 
        Mock New-AzureRmResourceGroupDeployment {}

        It "Change Password Validation Only" {
            $result = Set-AzVMResetPassword -ValidationOnly -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi" -Password "0575yR18]~t7T997Epbp#!DujDWUTW" -Verbose
            $result
        }

        It "Change Password" {
            $result = Set-AzVMResetPassword -ResourceGroupName kinmugiubt02 -VMName kinmugiubt02 -User "takekazu.omi" -Password "0575yR18]~t7T997Epbp#!DujDWUTW" -Verbose
            $result
        }

    }
}