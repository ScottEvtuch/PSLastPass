# Setup variables

    $ExportParams = @{}

    # Basic variables
    $LPURL = "https://lastpass.com"
    $LPUserAgent = "LastPass-CLI/1.2.1"

    # Import the PBKDF2 dll
    Add-Type -Path "$PSScriptRoot\lib\PBKDF2.NET.dll" -ErrorAction Stop

    # Set a variables for text encoding
    $BasicEncoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")
    $TextEncoding = [System.Text.Encoding]::GetEncoding("UTF-8")

    # Set up a session variable
    $LPSession = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession

    # Load saved data if possible
    try
    {
        $SavedData = Import-Clixml -Path "$env:APPDATA\PSLastPass.xml" -ErrorAction Stop

        $LPLogin = $SavedData.Login
        $LPKeys = $SavedData.LPKeys
        $LPIterations = $SavedData.Iterations

        $SavedData.Cookies | ForEach-Object {
        $LPSessionCookie = New-Object -TypeName System.Net.Cookie
            $_.psobject.Properties | Where-Object "Name" -NE "TimeStamp" | ForEach-Object {
                $LPSessionCookie.($_.Name) = $_.Value
            }
        $LPSession.Cookies.Add($LPSessionCookie)
    }
        if ($SavedData.Vault) {
            Write-Verbose "Importing saved vault data"
            $LPVault = $SavedData.Vault
        }
    }
    catch
    {
        Write-Verbose "No saved data to load: $_"
    }

#region Public Functions

    # Name of the folder for public function ps1 files
    $PublicFunctionFolder = "Public"

    # Setup variables
    $PublicFunctionPath = "$PSScriptRoot\$PublicFunctionFolder"
    $PublicFunctions = @()
    $PublicAliases = @()

    # Get all of the public function files we'll be importing
    Write-Verbose "Searching for scripts in $PublicFunctionPath"
    $PublicFunctionFiles = Get-ChildItem -File -Filter *-*.ps1 -Path $PublicFunctionPath -Recurse -ErrorAction Continue
    Write-Debug "Found $($PublicFunctionFiles.Count) function files in $PublicFunctionPath"

    # Iterate through each of the public function files
    foreach ($PublicFunctionFile in $PublicFunctionFiles)
    {
        $PublicFunctionName = $PublicFunctionFile.BaseName
        Write-Verbose "Importing function $PublicFunctionName"
        try
        {
            # Dot source the file and extract the function name and any aliases
            . $PublicFunctionFile.FullName
            $PublicFunctions += $PublicFunctionName
            $PublicFunctionAliases = Get-Alias -Definition $PublicFunctionName -Scope Local -ErrorAction Ignore
            Write-Debug "Aliases for $PublicFunctionName`: $PublicFunctionAliases"
            $PublicAliases += $PublicFunctionAliases
        }
        catch
        {
            Write-Error "Failed to import $($PublicFunctionFile): $_"
        }
    }

    # Add to the export parameters
    $ExportParams.Add("Function",$PublicFunctions)
    $ExportParams.Add("Alias",$PublicAliases)

#endregion

#region Private Functions

    # Name of the folder for private function ps1 files
    $PrivateFunctionFolder = "Private"

    # Setup variables
    $PrivateFunctionPath = "$PSScriptRoot\$PrivateFunctionFolder"

    # Get all of the private function files we'll be importing
    Write-Verbose "Searching for scripts in $PrivateFunctionPath"
    $PrivateFunctionFiles = Get-ChildItem -File -Filter *-*.ps1 -Path $PrivateFunctionPath -Recurse -ErrorAction Continue
    Write-Debug "Found $($PrivateFunctionFiles.Count) function files in $PrivateFunctionPath"

    # Iterate through each of the private function files
    foreach ($PrivateFunctionFile in $PrivateFunctionFiles)
    {
        $PrivateFunctionName = $PrivateFunctionFile.BaseName
        Write-Verbose "Importing function $PrivateFunctionName"
        try
        {
            # Dot source the file
            . $PrivateFunctionFile.FullName
        }
        catch
        {
            Write-Error "Failed to import $PrivateFunctionFile`: $_"
        }
    }

#endregion

# Export the public items

    Export-ModuleMember @ExportParams