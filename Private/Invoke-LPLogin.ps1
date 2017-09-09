<#
.Synopsis
   Logs in to LastPass
.DESCRIPTION
   Retrieves the number of iterations for the user. Uses PBKDF2.NET to create
   the encryption key and the login hex string. Sends the login request to
   LastPass and throws an error if it fails.
.EXAMPLE
   Invoke-LPLogin
#>
function Invoke-LPLogin
{
    [CmdletBinding()]
    Param()

    Process
    {
        Write-Verbose "Setting up common variables"
        $CommonSettings = @{
            "UserAgent" = $LPUserAgent;
            "WebSession" = $LPSession;
            "UseBasicParsing" = $true;
            "ErrorAction" = "Stop";
        }
        
        Write-Verbose "Getting the number of iterations"
        try
        {
            $IterationsResponse = Invoke-WebRequest -Uri "$LPUrl/iterations.php" -Method Post -Body @{"username"=$LPCredentials.UserName.ToLower();} @CommonSettings
            $Iterations = [int] $IterationsResponse.Content
        }
        catch
        {
            throw "Failed to get iterations from LastPass API: $_"
        }

        Write-Verbose "Producing the keys"
        try
        {
            $UsernameBytes = $Encoding.GetBytes($LPCredentials.UserName.ToLower())
            $PasswordBytes = $Encoding.GetBytes($LPCredentials.GetNetworkCredential().Password)

            $KeyPBKDF2 = [System.Security.Cryptography.PBKDF2]::new($PasswordBytes,$UsernameBytes,$Iterations,"HMACSHA256")
            $KeyBytes = $KeyPBKDF2.GetBytes(32)
            $KeyString = $Encoding.GetString($KeyBytes) | ConvertTo-SecureString -AsPlainText -Force
            
            $LoginPBKDF2 = [System.Security.Cryptography.PBKDF2]::new($KeyBytes,$PasswordBytes,1,"HMACSHA256")
            $LoginBytes = $LoginPBKDF2.GetBytes(32)
            $LoginString = [System.BitConverter]::ToString($LoginBytes).Replace("-","").ToLower()

            $script:LPKeys = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @($LoginString,$KeyString)
        }
        catch
        {
            throw "Failed to generate the login and decryption keys: $_"
        }

        Write-Verbose "Attempting to login"
        try
        {
            $LoginBody = @{
                "xml" = 2;
                "username" = $LPCredentials.UserName.ToLower();
                "hash" = $LPKeys.UserName;
                "iterations" = $Iterations;
                "includeprivatekeyenc" = 1;
                "method" = "cli";
                "outofbandsupported" = 1;
            }

            $LoginResponse = Invoke-WebRequest -Uri "$LPUrl/login.php" -Method Post -Body $LoginBody @CommonSettings
            Write-Debug $($LoginResponse | Out-String)

            switch ($([xml]$LoginResponse.Content).response.error.cause) {
                $null
                {
                    if ($([xml]$LoginResponse.Content).response.ok)
                    {
                        Write-Verbose "Sucessful login"
                        $([xml]$LoginResponse.Content).response.ok
                    }
                    else
                    {
                        throw "Malformed response from server"
                    }
                }
                "outofbandrequired"
                {
                    Write-Verbose "Trying login again with out of band request"
                    $LoginBody.Add("outofbandrequest",1)
                    $LoginResponse = Invoke-WebRequest -Uri "$LPUrl/login.php" -Method Post -Body $LoginBody @CommonSettings
                    Write-Debug $($LoginResponse | Out-String)

                    if ($([xml]$LoginResponse.Content).response.error)
                    {
                        throw "$($([xml]$LoginResponse.Content).response.error.message)"
                    }
                    if ($([xml]$LoginResponse.Content).response.ok)
                    {
                        Write-Verbose "Sucessful login"
                        $([xml]$LoginResponse.Content).response.ok
                    }
                    else
                    {
                        throw "Malformed response from server"
                    }
                }
                Default
                {
                    throw "$($([xml]$LoginResponse.Content).response.error.message)"
                }
            }
        }
        catch
        {
            throw "Failed to login: $_"
        }
    }
}