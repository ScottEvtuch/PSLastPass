<#
.Synopsis
   Returns account objects from the encrypted vault
.DESCRIPTION
   Iterates through all of the ACCT objects from the vault, decrypts them
   with the user's key, and then returns an array of objects.
.EXAMPLE
   Get-LPAccounts
#>
function Get-LPAccounts
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
    }
    Process
    {
        $VaultAccounts = $LPVault | Where-Object -Property 'ID' -EQ 'ACCT'

        $Accounts = @()
        foreach ($VaultAccount in $VaultAccounts)
        {
            $AccountBytes = $Encoding.GetBytes($VaultAccount.Data)

            $AccountCursor = 0
            $AccountData = @()
            while ($AccountCursor -lt $AccountBytes.Count)
            {
                Write-Verbose "Cursor is $AccountCursor"
                $Length = [System.BitConverter]::ToUInt32($AccountBytes[$($AccountCursor+3)..$AccountCursor],0)
                Write-Debug "Data item length is $Length"
                $AccountCursor = $AccountCursor + 4

                $DataItem = $Encoding.GetString($AccountBytes[$AccountCursor..$($AccountCursor+$Length-1)])
                $AccountCursor = $AccountCursor + $Length
    
                $AccountData += $DataItem
            }

            $AccountData = $AccountData | ConvertFrom-LPEncryptedString
            
            $Username = $AccountData[7]
            $Password = $AccountData[8] | ConvertTo-SecureString -AsPlainText -Force

            $Account = @{
                "ID" = $AccountData[0];
                "Name" = $AccountData[1];
                "Group" = $AccountData[2];
                "URL" = $AccountData[3] | ConvertFrom-LPHexString;
                "Notes" = $AccountData[4];
                "PSCredential" = New-Object -TypeName PSCredential -ArgumentList @($Username,$Password);
                "Username" = $AccountData[7];
                "Password" = $AccountData[8];
                "SecureNote" = $AccountData[11];
                "Data" = $AccountData[12..$AccountData.Count];
            }

            $Accounts += New-Object -TypeName PSObject -Property $Account
        }

        $Accounts
    }
}