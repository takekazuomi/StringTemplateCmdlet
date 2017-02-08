Import-Module "$PSScriptRoot/../../StringTemplateCmdlet" -Force -Verbose

Set-StrictMode -Version Latest

Describe "arm template parameters module" {
    It "simple many" {
        # array of hash
        $parameters = @(
            [ordered]@{
                name = "hostname"
                defaultValue = "test.example.com"
                type=[string]"string"
                metadata = @{
                    description = "Unique DNS Name for the Public IP used to access the Virtual Machine."
                }
            }
        )
 
        $result = $parameters | Convert-StTemplate -GroupPath $PSScriptRoot/st/parameters.stg -TemplateName parameters -Verbose
        Write-Host "result:" $result
    }

    It "simple many" {

    }

    It "secure string" {
    }

    It "selection" {
    }

    It "default selection" {
    }

    It "meta data" {
    }
}

Describe "debugByPipe" {
    It "debug type" {
        $parameters = [PSCustomObject]@{type="hello st"}
        $result = $parameters | Convert-StTemplate -GroupPath $PSScriptRoot/st/parameters.stg -TemplateName debug -Verbose
        Write-Host "result:" $result
    }
}

Describe "debugByParam" {
    It "debug type" {
        $parameters = [PSCustomObject]@{type="hello st"}
        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/parameters.stg -TemplateName debug  -parameters $parameters -Verbose
        Write-Host "result:" $result
    }
}

Describe "debugHashByPipe" {
    It "debug type" {
        $parameters = [ordered]@{type="hello st"}
        $result = $parameters | Convert-StTemplate -GroupPath $PSScriptRoot/st/parameters.stg -TemplateName debug -Verbose
        Write-Host "result:" $result
    }
}

