@{
    RootModule = 'azure-ssh.psm1'
    NestedModules = @("bin\debug\StringTemplateCmdlet.dll")
    ModuleVersion = '0.1'
    GUID = '5714753b-2afd-4492-a5fd-01d9e2cff8b5'
    Author = 'Takekazu Omi'
    CompanyName = 'kyrt inc.'
    Copyright = '(c) kyrt inc. All rights reserved.'
    Description = 'azure ssh helper'
    PowerShellVersion = '5.0'
    DotNetFrameworkVersion = '4.0'
    CLRVersion = '4.0'
    RequiredModules = @("posh-git")
    CmdletsToExport = 'Convert-StTemplate'
    HelpInfoURI = 'http://kyrt.in'
}
