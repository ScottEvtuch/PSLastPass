<#
.Synopsis
   Prompts the user for credentials
.DESCRIPTION
   TODO
.EXAMPLE
   Get-LPCredentials
#>
function Get-LPCredentials
{
    [CmdletBinding()]
    Param()

    Process
    {
        Write-Verbose "Prompting the user for credentials"        
        $LPCredentials = Get-Credential -Message "Please input your credentials"

        $script:LPCredentials = $LPCredentials
        $script:LPCredentials
    }
}