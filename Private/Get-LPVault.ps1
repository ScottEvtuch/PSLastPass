<#
.Synopsis
   Retrieves the LastPass vault
.DESCRIPTION
   Downloads the vault payload from the LastPass API and iterates over the
   VaultItems to create an individual PowerShell object for each.
.EXAMPLE
   Get-LPVault
#>
function Get-LPVault
{
    [CmdletBinding()]
    Param()

    Begin
    {
        Invoke-LPLogin
    }
    Process
    {
        Write-Verbose "Setting up common variables"
        $CommonSettings = @{
            "UserAgent" = $LPUserAgent;
            "WebSession" = $LPSession;
            "UseBasicParsing" = $true;
            "ErrorAction" = "Stop";
        }
        
        Write-Verbose "Getting the vault"
        try
        {
            $VaultBody = @{
                "mobile" = 1;
                "requestsrc" = "cli";
                "hasplugin" = "1.2.1";
            }

            $VaultResponse = Invoke-WebRequest -Uri "$LPUrl/getaccts.php" -Method Post -Body $VaultBody @CommonSettings
        }
        catch
        {
            throw "Failed to get vault from LastPass API: $_"
        }

        Write-Verbose "Converting vault into raw bytes"
        $VaultBytes = $Encoding.GetBytes($VaultResponse.Content)

        $VaultCursor = 0
        $Vault = @()
        Write-Verbose "Iterating through the vault entries"
        while ($VaultCursor -lt $VaultBytes.Count)
        {
            Write-Debug "Cursor is $VaultCursor"
            $ID = $Encoding.GetString($VaultBytes[$VaultCursor..$($VaultCursor+3)])
            Write-Debug "Entry ID is $ID"
            $VaultCursor = $VaultCursor + 4
            $Length = [System.BitConverter]::ToUInt32($VaultBytes[$($VaultCursor+3)..$VaultCursor],0)
            Write-Debug "Entry length is $Length"
            $VaultCursor = $VaultCursor + 4
            $Data = $VaultBytes[$VaultCursor..$($VaultCursor+$Length-1)]
            $VaultCursor = $VaultCursor + $Length

            Write-Verbose "Adding item with ID $ID"
            $VaultItem = @{
                "ID" = $ID;
                "Length" = $Length;
                "Data" = $Encoding.GetString($Data);
            }
            $Vault += New-Object -TypeName PSObject -Property $VaultItem
        }

        $script:LPVault = $Vault
    }
}