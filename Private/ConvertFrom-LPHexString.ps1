<#
.Synopsis
   Returns the plaintext for a hex string from the LastPass vault
.DESCRIPTION
   Loops through the hex characters in a string and returns a decoded string.
.EXAMPLE
   ConvertFrom-LPHexString -String $String
#>
function ConvertFrom-LPHexString
{
    [CmdletBinding()]
    Param(
        # The encrypted string to decrypt
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $String
    )

    Process
    {
        $CharArray = @()

        Write-Verbose "Converting from Hex string"
        Write-Debug "Hex string: $String"
        for ($i = 0; $i -lt $String.Length; $i = $i + 2)
        {
            if ($BasicEncoding.GetBytes($String.Substring($i,2)) -ne [byte]16)
            {
                $CharArray += [char][System.Convert]::ToInt16($String.Substring($i,2),16)
            }
        }

        -join $CharArray
    }
}