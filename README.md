# PSLastPass
An unofficial PowerShell module for invoking the LastPass API

# Attribution

This project utilizes the [PBKDF2.NET library by Michael Johnson](https://github.com/therealmagicmike/PBKDF2.NET) licensed under the [MIT License](https://raw.githubusercontent.com/therealmagicmike/PBKDF2.NET/master/License.txt).

# Usage

## General Notes

When the module is first loaded, regardless of command, it will prompt you for your LastPass credentials or load your saved credentials and attempt to login. Saved credentials are encrypted so that only the same user account on the same machine can decrypt them.

Passwords of any type are never stored in plaintext anywhere. Your LastPass email and the contents of your session cookie are stored in plaintext as variables and on your disk if you use Save-LPData.

While the module is loaded, your entry names, URLs, usernames, and notes will be stored unencrypted in module-scoped PowerShell variables.

## Caching and Offline Use

New caching behavior in v1.2 means that Save-LPData will now only save your credentials by default. Any subsequent module imports will cause the vault to be retrieved from the LastPass API. You can return to the previous behavior by adding the -SaveVault switch parameter which will save the entire vault offline for future use. You can also force an update of the vault by running Sync-LPData or adding the -Refresh switch parameter to any Get function.

## Get-LPCredential

This command will return a PSCredential object for the best matching entry for a URL. If more than one entry exists that is equally specific (based on protocol, port number, directory, and query string) then they will all be returned unless you specify the "First" switch.

```
Get-LPCredential "https://example.com" -First

UserName         Password
--------         --------
username         System.Security.SecureString
```

You can also use this command (or its alias "lastpass") inline with other PowerShell commands that take a PSCredential parameter

```
Enter-PSSession -ComputerName server.example.com -Credential (lastpass server.example.com)
```

## Get-LPAccounts

This command will return an array of all of your LastPass entries.

```
Get-LPAccounts | Where-Object Name -Like "*example*"


URL          : https://example.com/
ID           : 1234567890
Username     : username
Password     : System.Security.SecureString
Notes        : Same as the combination on my luggage
SecureNote   : 0
Name         : Example Site
Group        : Best sites ever
PSCredential : System.Management.Automation.PSCredential
```

## Save-LPData

This command will save your LastPass credentials, cookie, and optionally your encrypted vault to the %APPDATA% directory on your machine. Everything that is saved is encrypted with the exception of your LastPass email address, its PBKDF2 hash, and the cookie.

```
Save-LPData -SaveVault
```

## Sync-LPData

This command forces a refresh of your LastPass data including any new entries you have added since the module was loaded or the vault was saved with Save-LPData.

```
Sync-LPData
```
