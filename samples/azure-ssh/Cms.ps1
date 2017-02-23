function Decrypt-CmsContent {
    param(
        [string]$CertThumbprint,
        [Parameter(ParameterSetName="base64")]
        $Base64String,
        [Parameter(ParameterSetName="hex")]
        [string]$Hex,
        [Parameter(ParameterSetName="bytes")]
        [byte[]]$Bytes
    )
    Add-Type -assemblyName "System.Security"

    switch ($PsCmdlet.ParameterSetName) 
    { 
        "base64" { $Bytes=[System.Convert]::FromBase64String($Base64String);break} 
        "hex" { $Bytes= $Hex-split "(?<=\G\w{2})(?=\w{2})" | %{ [Convert]::ToByte( $_, 16 )};break} 
    } 

    $cert = Get-Item Cert:\LocalMachine\My\$CertThumbprint
    $cms = New-Object System.Security.Cryptography.Pkcs.EnvelopedCms
    $cms.Decode($Bytes)
    $cms.Decrypt($cert)

    [Text.Encoding]::UTF8.GetString($cms.ContentInfo.Content)
}

function Encrypt-CmsContent {
    param(
        [string]$CertThumbprint,
        [Parameter(ParameterSetName="string")]
        [string]$String,
        [Parameter(ParameterSetName="hex")]
        [string]$Hex,
        [Parameter(ParameterSetName="bytes")]
        [byte[]]$Bytes,
        [ValidateSet("hex", "base64")]
        $OutputEncoding
    )

    Add-Type -assemblyName "System.Security"

    switch ($PsCmdlet.ParameterSetName) 
    { 
        "string" { $Bytes=[Text.Encoding]::UTF8.GetBytes($String);break} 
        "hex" { $Bytes= $Hex-split "(?<=\G\w{2})(?=\w{2})" | %{ [Convert]::ToByte( $_, 16 )};break} 
    } 

    $cert = Get-Item Cert:\LocalMachine\My\$CertThumbprint

    $content = New-Object Security.Cryptography.Pkcs.ContentInfo -argumentList (,$Bytes)
    $envelop = New-Object Security.Cryptography.Pkcs.EnvelopedCms $content
    $recpient = (New-Object System.Security.Cryptography.Pkcs.CmsRecipient($cert))
    $envelop.Encrypt($recpient)

    switch($OutputEncoding)
    {
        "hex" {$envelop.Encode();break}
        "base64" {[Convert]::ToBase64String($envelop.Encode());break}
    }
}
