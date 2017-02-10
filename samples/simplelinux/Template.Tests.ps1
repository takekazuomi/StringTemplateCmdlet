Import-Module "$PSScriptRoot/../../StringTemplateCmdlet" -Force -Verbose

Set-StrictMode -Version Latest

Describe -Tag "parameters" "arm template parameters module" {
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

Describe -Tag "variables" "arm template variables module" {
    It "simple many" {
        # array of hash
        $variables =[ordered]@{
            storageAccountName= "[concat(uniquestring(resourceGroup().id), 'salinuxvm')]"
            dataDisk1VhdName= "datadisk1"
            imagePublisher= "Canonical"
            imageOffer= "UbuntuServer"
            OSDiskName= "osdiskforlinuxsimple"
            nicName= "myVMNic"
            addressPrefix= "10.0.0.0/16"
            subnetName= "Subnet"
            subnetPrefix= "10.0.0.0/24"
            storageAccountType= "Standard_LRS"
            publicIPAddressName= "myPublicIP"
            publicIPAddressType= "Dynamic"
            vmStorageAccountContainerName= "vhds"
            vmName= "MyUbuntuVM"
            vmSize= "Standard_A1"
            virtualNetworkName= "MyVNET"
            vnetID= "[resourceId('Microsoft.Network/virtualNetworks',variables('virtualNetworkName'))]"
            subnetRef= "[concat(variables('vnetID'),'/subnets/',variables('subnetName'))]"
        }

        $result = $variables | Convert-StTemplate -GroupPath $PSScriptRoot/st/variables.stg -TemplateName variables
        Write-Host "result:" $result
    }
}

Describe  "debugByPipe" {
    It -Skip "debug type" {
        $parameters = [PSCustomObject]@{type="hello st"}
        $result = $parameters | Convert-StTemplate -GroupPath $PSScriptRoot/st/parameters.stg -TemplateName debug -Verbose
        Write-Host "result:" $result
    }
}

Describe "debugByParam" {
    It -Skip "debug type" {
        $parameters = [PSCustomObject]@{type="hello st"}
        $result = Convert-StTemplate -GroupPath $PSScriptRoot/st/parameters.stg -TemplateName debug  -parameters $parameters -Verbose
        Write-Host "result:" $result
    }
}

Describe "debugHashByPipe" {
    It -Skip "debug type" {
        $parameters = [ordered]@{type="hello st"}
        $result = $parameters | Convert-StTemplate -GroupPath $PSScriptRoot/st/parameters.stg -TemplateName debug -Verbose
        Write-Host "result:" $result
    }
}

