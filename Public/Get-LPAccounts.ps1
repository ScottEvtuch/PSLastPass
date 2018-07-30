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
        if (!$LPAccounts)
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
    }
    Process
    {
        if (!$LPAccounts)
        {
            $VaultAccounts = $LPVault | Where-Object -Property 'ID' -Match "(ACCT|SHAR)"

            $SharingKey = $null
            $LPAccounts = @()
            foreach ($VaultAccount in $VaultAccounts)
            {
                switch ($VaultAccount.ID) {
                    'ACCT'
                    {
                        Write-Debug "Starting ACCT processing"
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
                        $AccountData = $AccountData
                        

                        $Username = $AccountData[7] | ConvertFrom-LPEncryptedString -Key $SharingKey
                        $Password = $AccountData[8] | ConvertFrom-LPEncryptedString -Key $SharingKey | ConvertTo-SecureString -AsPlainText -Force
            
                        $Account = @{
                            "ID" = $AccountData[0] | ConvertFrom-LPEncryptedString;
                            "Name" = $AccountData[1] | ConvertFrom-LPEncryptedString -Key $SharingKey;
                            "Group" = $AccountData[2] | ConvertFrom-LPEncryptedString -Key $SharingKey;
                            "URL" = $AccountData[3] | ConvertFrom-LPEncryptedString | ConvertFrom-LPHexString;
                            "Notes" = $AccountData[4] | ConvertFrom-LPEncryptedString -Key $SharingKey;
                            "PSCredential" = New-Object -TypeName PSCredential -ArgumentList @($Username,$Password);
                            "Username" = $Username;
                            "Password" = $Password;
                            "SecureNote" = $AccountData[11] | ConvertFrom-LPEncryptedString;
                        }

                        $LPAccounts += New-Object -TypeName PSObject -Property $Account
                    }
                    'SHAR'
                    {
                        Write-Debug "Starting SHAR processing"
                        $ShareBytes = $Encoding.GetBytes($VaultAccount.Data)

                        $ShareCursor = 0
                        $ShareData = @()
                        while ($ShareCursor -lt $ShareBytes.Count)
                        {
                            Write-Verbose "Cursor is $ShareCursor"
                            $Length = [System.BitConverter]::ToUInt32($ShareBytes[$($ShareCursor+3)..$ShareCursor],0)
                            Write-Debug "Data item length is $Length"
                            $ShareCursor = $ShareCursor + 4

                            $DataItem = $Encoding.GetString($ShareBytes[$ShareCursor..$($ShareCursor+$Length-1)])
                            $ShareCursor = $ShareCursor + $Length

                            $ShareData += $DataItem
                        }

                        $SharingKey = $ShareData[5] | ConvertFrom-LPEncryptedString | ConvertFrom-LPHexString
                    }
                }
            }
        }

        $script:LPAccounts = $LPAccounts
        $script:LPAccounts
    }
}