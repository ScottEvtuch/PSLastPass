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
    Param(
        # Optionally save the vaulted passwords offline
        [Parameter()]
        [Switch]
        $SaveVault
    )

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
            $SavedData = @{
                'Login' = $LPLogin
                'LPKeys' = $LPKeys
                'Iterations' = $LPIterations
                'Cookies' = $LPSession.Cookies.GetCookies($LPURL)
            }
            if ($SaveVault) {
                $SavedData.Vault = $LPVault
            }
            $SavedData | Export-CliXml $env:APPDATA\PSLastPass.xml
        }
        catch {
            throw "Failed to export LastPass data: $_"
        }
    }
}