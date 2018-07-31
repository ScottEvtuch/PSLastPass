<#
.Synopsis
   Prompts the user for credentials
.DESCRIPTION
   Uses Get-Credential to prompt the user and save a PSCredential object with
   the user's LastPass login.
.EXAMPLE
   Get-LPLogin
#>
function Get-LPLogin
{
    [CmdletBinding()]
    Param()

    Process
    {
        Write-Verbose "Prompting the user for credentials"        
        $LPLogin = Get-Credential -Message "Please input your LastPass credentials"

        if (!$LPLogin)
        {
            throw "No credentials provided"
        }

        $script:LPLogin = $LPLogin
        $script:LPLogin
    }
}