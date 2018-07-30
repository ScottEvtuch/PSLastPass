<#
.Synopsis
   Saves the encrypted LastPass data to the user's APPDATA
.DESCRIPTION
   Runs Export-CliXml to a file in the user's APPDATA directory so that future
   module loads can pull the cached data instead of contacting LastPass.
.EXAMPLE
   Save-LPData
#>
function Save-LPData
{
    [CmdletBinding()]
    Param()

    Begin
    {
        if (!$LPVault)
        {
            $LPVault = Get-LPVault
        }
        if (!$LPKeys)
        {
            $LPKeys = Get-LPKeys
        }
        if (!$LPAccounts)
        {
            $LPAccounts = Get-LPAccounts
        }
    }
    Process
    {
        try {
            @{
                'Credentials' = $LPCredentials
                'LPKeys' = $LPKeys
                'Iterations' = $LPIterations
                'Cookies' = $LPSession.Cookies.GetCookies($LPURL)
                'Vault' = $LPVault
                'Accounts' = $LPAccounts
            } | Export-CliXml $env:APPDATA\PSLastPass.xml
        }
        catch {
            throw "Failed to export LastPass data: $_"
        }
    }
}