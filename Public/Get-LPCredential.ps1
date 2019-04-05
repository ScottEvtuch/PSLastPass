<#
.Synopsis
   Returns a PSCredential object for a URL
.DESCRIPTION
   Performs a regular expression match on a URL to create strings for various
   fuzzy matching scenarios, then returns an array of PSCredential objects
   that match the given URL. Optionally return only one entry.
.EXAMPLE
   Get-LPCredential
#>
function Get-LPCredential
{
    [CmdletBinding(PositionalBinding=$true,
                    DefaultParameterSetName='URL',
                    ConfirmImpact='Low')]
    [Alias("lastpass")]
    Param
    (
        # URL to find a credential for
        [Parameter(Mandatory=$true,
                    ParameterSetName='URL',
                    Position=0,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $URL,

        # Only return the first result
        [Parameter()]
        [switch]
        $First
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
        if (!($URL -match '(((((?:\w+\:\/\/)?(((?:\d{1,3}\.){3}\d{1,3})|(?:\w+\.)*((?:\w+\.)(?:\w+))|\w+))(?:\:\d+)?)(?:\/[^\?\.]*)*(?:\/)?(?:[-\w\.]*)?)(?:\??[^\/]*)?)?'))
        {
            throw "Bad URL format"
        }

        Write-Verbose "Searching through $($LPAccounts.Count) accounts"
        foreach ($match in $matches.GetEnumerator()) {
            Write-Verbose "Searching for: $($match.Value)"
            $Candidates = @($LPAccounts | Where-Object PSCredential -NE $null | Where-Object {$_.URL -like "*$($match.Value)" -or $_.URL -like "*$($match.Value)/*" -or $_.URL -like "*$($match.Value):*"})
            Write-Verbose "Found $($Candidates.Count) candidates"
            if ($Candidates.Count -gt 0)
            {
                if ($First)
                {
                    return $($Candidates.PSCredential | Select-Object -First 1)
                }
                else
                {
                    return $Candidates.PSCredential
                }
            }
        }

        throw "No matches found in LastPass vault"

    }
}