# Variables configured in form
$roomMailbox = $form.gridmailbox
$roomMailboxDisplayName = $form.displayName
$roomMailboxMailPrefix = $form.mailPrefix
$roomMailboxMailDomain = $form.mailDomain.id
$blnSetAsPrimaryEmail = [System.Convert]::ToBoolean($form.blnSetAsPrimaryEmail)

# Build proxy address with appropriate prefix based on whether it should be primary
if ($blnSetAsPrimaryEmail) {
    $roomMailboxProxyAddress = "SMTP:$($roomMailboxMailPrefix)@$($roomMailboxMailDomain)"
}
else {
    $roomMailboxProxyAddress = "smtp:$($roomMailboxMailPrefix)@$($roomMailboxMailDomain)"
}
$roomMailboxAlias = $form.alias
$roomMailboxCapacity = $form.resourceCapacity

# Global variables
# Outcommented as these are set from Global Variables
# $ExchangeConnectionUri = ""
# $ExchangeAdminUsername = ""
# $ExchangeAdminPassword = ""

# Fixed values
$commands = @(
    "Set-Mailbox"
)

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
#endregion functions

try {
    # Create credentials
    $actionMessage = "creating credentials object"
    
    $securePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $securePassword)
    
    Write-Verbose "Created credentials for user [$ExchangeAdminUsername]"

    # Connect to Exchange On-Premises
    # Docs: https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell
    $actionMessage = "connecting to Exchange On-Premises"

    $sessionOptionParams = @{
        SkipCACheck         = $false
        SkipCNCheck         = $false
        SkipRevocationCheck = $false
    }

    $sessionOption = New-PSSessionOption @sessionOptionParams

    $sessionParams = @{
        Authentication    = 'Default'
        ConfigurationName = 'Microsoft.Exchange'
        Credential        = $credential
        ConnectionUri     = $ExchangeConnectionUri
        SessionOption     = $sessionOption
        ErrorAction       = "Stop"
    }

    $exchangeSession = New-PSSession @sessionParams
    $null = Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber -CommandName $commands -ErrorAction Stop

    # Send initial audit log
    $Log = @{
        Action            = "DeleteResource" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = "Successfully connected to Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
    }
    Write-Information -Tags "Audit" -MessageData $log

    # Get current email addresses and prepare new email address list, while keeping existing proxy addresses (except the current address if already present)
    $currentAddresses = $roomMailbox.EmailAddresses
    $proxyAddresses = @()

    # Extract the email address without prefix for comparison
    $emailAddressOnly = $roomMailboxProxyAddress -replace '^(smtp|SMTP):', ''
       
    foreach ($address in $currentAddresses) {
        # If setting as primary, convert any existing primary SMTP to secondary
        if ($blnSetAsPrimaryEmail -and $address.StartsWith('SMTP:')) {
            $address = $address -replace 'SMTP:', 'smtp:'
        }
        # Remove the address if it already exists (to avoid duplicates)
        if ($address -ne "smtp:$emailAddressOnly" -and $address -ne "SMTP:$emailAddressOnly") {
            $proxyAddresses += $address
        }
    }
    $proxyAddresses += $roomMailboxProxyAddress

    #region update shared mailbox
    $actionMessage = "updating shared mailbox"

    $updateMailboxParams = @{
        Identity         = $roomMailbox.Guid
        DisplayName      = $roomMailboxDisplayName
        Name             = $roomMailboxDisplayName
        ResourceCapacity = $roomMailboxCapacity
        EmailAddresses   = $proxyAddresses
        Alias            = $roomMailboxAlias
        Confirm          = $false
        ErrorAction      = 'Stop'
    }

    $null = Set-Mailbox @updateMailboxParams
    
    Write-Information  "Room Mailbox [$roomMailboxDisplayName] updated successfully" 
    $Log = @{
        Action            = "UpdateResource" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = "Room Mailbox [$roomMailboxDisplayName] updated successfully"  # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $roomMailboxDisplayName # optional (free format text) 
        TargetIdentifier  = $([string]$($roomMailbox.Guid)) # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log 
}
catch {
    $ex = $PSItem
    if (-not [string]::IsNullOrEmpty($ex.Exception.Message)) {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
    else {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception)"
    }

    # Send error audit log to HelloID
    $Log = @{
        Action            = "UpdateResource" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = $auditMessage # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $roomMailboxDisplayName # optional (free format text) 
        TargetIdentifier  = $([string]$($roomMailbox.Guid)) # optional (free format text) 
    }
    
    Write-Information -Tags "Audit" -MessageData $log
    Write-Warning $warningMessage
    Write-Error $auditMessage
}
finally {
    # Disconnect from Exchange
    # Docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/remove-pssession
    if ($null -ne $exchangeSession) {
        try {
            $deleteExchangeSessionSplatParams = @{
                Session     = $exchangeSession
                Confirm     = $false
                ErrorAction = "Stop"
            }
            $null = Remove-PSSession @deleteExchangeSessionSplatParams

            # Send disconnect audit log
            $Log = @{
                Action            = "UpdateResource" # optional. ENUM (undefined = default) 
                System            = "Exchange On-Premises" # optional (free format text) 
                Message           = "Successfully disconnected from Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
                IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
                TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
            }
            Write-Information -Tags "Audit" -MessageData $log
        }
        catch {
            Write-Warning "Failed to disconnect from Exchange using URI [$ExchangeConnectionUri]. Error: $($_.Exception.Message)"
        }
    }
}
