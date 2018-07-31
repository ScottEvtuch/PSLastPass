<#
.Synopsis
   Generates the encryption keys
.DESCRIPTION
   Retrieves the number of iterations for the user. Uses PBKDF2.NET to create
   the encryption key and the login hex string.
.EXAMPLE
   Get-LPKeys
#>
function Get-LPKeys
{
    [CmdletBinding()]
    Param()

    Begin
    {
        if (!$LPLogin)
        {
            $LPLogin = Get-LPLogin
        }
    }
    Process
    {
        Write-Verbose "Setting up common variables"
        $WebRequestSettings = @{
            "UserAgent" = $LPUserAgent;
            "WebSession" = $LPSession;
            "UseBasicParsing" = $true;
            "ErrorAction" = "Stop";
        }

        if (!$LPIterations)
        {
            Write-Verbose "Getting the number of iterations"
            try
            {
                $IterationsResponse = Invoke-WebRequest -Uri "$LPUrl/iterations.php" -Method Post -Body @{"username"=$LPLogin.UserName.ToLower();} @WebRequestSettings
                Write-Debug $($IterationsResponse | Out-String)
    
                $script:LPIterations = if ([int]$IterationsResponse.Content -eq 1) {100100} else {[int] $IterationsResponse.Content}
                Write-Debug "Using $LPIterations iterations"
            }
            catch
            {
                throw "Failed to get iterations from LastPass API: $_"
            }
        }

        Write-Verbose "Producing the keys"
        try
        {
            $UsernameBytes = $Encoding.GetBytes($LPLogin.UserName.ToLower())
            $PasswordBytes = $Encoding.GetBytes($LPLogin.GetNetworkCredential().Password)

            $KeyPBKDF2 = [System.Security.Cryptography.PBKDF2]::new($PasswordBytes,$UsernameBytes,$LPIterations,"HMACSHA256")
            $KeyBytes = $KeyPBKDF2.GetBytes(32)
            $KeyString = $Encoding.GetString($KeyBytes) | ConvertTo-SecureString -AsPlainText -Force

            $LoginPBKDF2 = [System.Security.Cryptography.PBKDF2]::new($KeyBytes,$PasswordBytes,1,"HMACSHA256")
            $LoginBytes = $LoginPBKDF2.GetBytes(32)
            $LoginString = [System.BitConverter]::ToString($LoginBytes).Replace("-","").ToLower()

            $script:LPKeys = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($LoginString,$KeyString)
            $script:LPKeys
        }
        catch
        {
            throw "Failed to generate the login and decryption keys: $_"
        }
    }
}