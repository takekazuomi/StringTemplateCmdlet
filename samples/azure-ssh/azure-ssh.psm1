Push-Location $PSScriptRoot
. .\Utils.ps1
. .\SshConfig.ps1
. .\VMAccess.ps1
. .\CustomScript.ps1
Pop-Location

Export-ModuleMember `
    -Function @(
        'Get-AzSshConfig'
        'Get-AzSshJumpboxConfig'
        'Get-AzSshRemoteDesktopFile'
        'Copy-SshId'
        'Set-AzVMUserCredentials'
        'Remove-AzVMUser'
        'Set-AzVMCustomScript'
        'Set-FileToBlob'
        'Get-AzKeylist',
        'Encrypt-CmsContent',
        'Decrypt-CmsContent'
    )

