<#
.Synopsis
   Force updates LastPass data from the online database
.DESCRIPTION
   Runs Get-LPVault, Get-LPKeys, and Get-LPAccounts with the refresh flag
   forced to make sure the modules data is up to date.
.EXAMPLE
   Sync-LPData
#>
function Sync-LPData
{
    [CmdletBinding()]
    Param()

    Process
    {
        $LPVault = Get-LPVault
        $LPKeys = Get-LPKeys
        $LPAccounts = Get-LPAccounts -Refresh
    }
}
