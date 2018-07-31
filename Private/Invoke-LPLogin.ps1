<#
.Synopsis
   Logs in to LastPass
.DESCRIPTION
   Sends the login request to LastPass and throws an error if it fails.
.EXAMPLE
   Invoke-LPLogin
#>
function Invoke-LPLogin
{
    [CmdletBinding()]
    Param()

    Begin
    {
        if (!$LPKeys)
        {
            $LPKeys = Get-LPKeys
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

        Write-Verbose "Attempting to login"
        try
        {
            $LoginBody = @{
                "xml" = 2;
                "username" = $LPLogin.UserName.ToLower();
                "hash" = $LPKeys.UserName;
                "iterations" = $LPIterations;
                "includeprivatekeyenc" = 1;
                "method" = "cli";
                "outofbandsupported" = 1;
            }

            $LoginResponse = Invoke-WebRequest -Uri "$LPUrl/login.php" -Method Post -Body $LoginBody @WebRequestSettings
            Write-Debug $($LoginResponse | Out-String)

            switch ($([xml]$LoginResponse.Content).response.error.cause) {
                $null
                {
                    if ($([xml]$LoginResponse.Content).response.ok)
                    {
                        Write-Verbose "Sucessful login"
                    }
                    else
                    {
                        throw "Malformed response from server"
                    }
                }
                "outofbandrequired"
                {
                    Write-Host "Out of band authentication is required"
                    Write-Verbose "Trying login again with out of band request"
                    $LoginBody.Add("outofbandrequest",1)
                    $LoginResponse = Invoke-WebRequest -Uri "$LPUrl/login.php" -Method Post -Body $LoginBody @WebRequestSettings
                    Write-Debug $($LoginResponse | Out-String)

                    if ($([xml]$LoginResponse.Content).response.error)
                    {
                        throw "$($([xml]$LoginResponse.Content).response.error.message)"
                    }
                    if ($([xml]$LoginResponse.Content).response.ok)
                    {
                        Write-Verbose "Sucessful login"
                    }
                    else
                    {
                        throw "Malformed response from server"
                    }
                }
                "unknownpassword"
                {
                    Write-Host "Invalid LastPass password"
                    $script:LPLogin = $null
                }
                Default
                {
                    throw "$($([xml]$LoginResponse.Content).response.error.message)"
                }
            }

            $script:LPSession = $LPSession
            $LPSession
        }
        catch
        {
            throw "Failed to login: $_"
        }
    }
}