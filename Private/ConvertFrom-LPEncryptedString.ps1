<#
.Synopsis
   Returns the plaintext for an AES-encrypted string from the LastPass vault
.DESCRIPTION
   Uses the decryption key from the user's password to AES decrypt their vault
   entires. Returns the unencrytped string.
.EXAMPLE
   ConvertFrom-LPEncryptedString -String $String
#>
function ConvertFrom-LPEncryptedString
{
    [CmdletBinding()]
    Param(
        # The encrypted string to decrypt
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $String,

        # The applicable sharing key
        [String]
        $Key
    )

    Begin
    {
        if (!$LPKeys)
        {
            Invoke-LPLogin | Out-Null
        }
        if ($Key)
        {
            $KeyBytes = $Encoding.GetBytes($Key)
        }
        else
        {
            $KeyBytes = $Encoding.GetBytes($LPKeys.GetNetworkCredential().Password)
        }
    }
    Process
    {
        if (($String[0] -eq '!') -and (($String.Length % 16) -eq 1) -and ($String.Length -gt 32))
        {
            Write-Verbose "Decrypting using AES"
            $StringBytes = $Encoding.GetBytes($String)
            $AES = New-Object -TypeName "System.Security.Cryptography.AesManaged"
            $AES.Key = $KeyBytes
            $AES.IV = $StringBytes[1..16]
            $AES.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
            $Decryptor = $AES.CreateDecryptor()
            $PlainBytes = $Decryptor.TransformFinalBlock($StringBytes,17,$($StringBytes.Length-17))
            $OutString = $Encoding.GetString($PlainBytes)
            $Decryptor.Dispose()
            $AES.Dispose()
        }
        else
        {
            Write-Verbose "Not AES encrypted, returning unaltered string"
            $OutString = $String
        }

        $OutString.Trim([byte]0)
    }
}