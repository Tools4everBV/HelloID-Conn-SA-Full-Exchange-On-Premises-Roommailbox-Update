# HelloID-Conn-SA-Full-Exchange-On-Premises-Roommailbox-Update

| :information_source: Information                                                                                                                                                                                                                                                                                                                                                          |
| :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| This repository contains the connector and configuration code only. The implementer is responsible for acquiring the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

## Description

_HelloID-Conn-SA-Full-Exchange-On-Premises-Roommailbox-Update_ is a template designed for use with HelloID Service Automation (SA) Delegated Forms. It can be imported into HelloID and customized according to your requirements.

By using this delegated form, you can update Exchange On-Premises room mailbox properties. The following options are available:

1.  Search and select a room mailbox by name, alias, or primary SMTP address
2.  Enter new values for the room mailbox attributes (display name, alias, email address, resource capacity)
3.  Select a mail domain from the available accepted domains in Exchange
4.  Toggle whether to set the new email address as primary or secondary
5.  The entered values are validated in real-time for uniqueness in Exchange On-Premises
6.  Room mailbox attributes are updated in Exchange On-Premises
7.  Existing proxy addresses are preserved unless they match the new address
8.  Comprehensive audit logging is written back to HelloID

## Getting started

### Requirements

- **Exchange On-Premises Environment**:<br>
  Access to an Exchange On-Premises server with PowerShell remoting enabled. The connector uses remote PowerShell sessions to manage room mailboxes.
- **Service Account**:<br>
  A service account with appropriate permissions to manage mailboxes in Exchange On-Premises. The account must have permissions to run `Get-Mailbox`, `Get-Recipient`, `Get-AcceptedDomain`, and `Set-Mailbox` cmdlets.
- **PowerShell Remoting**:<br>
  PowerShell remoting must be enabled on the Exchange server. The connection URI typically follows the format: `http(s)://<ExchangeServer>/powershell`
- **Network Connectivity**:<br>
  The HelloID agent or server must have network access to the Exchange On-Premises server on the PowerShell remoting port (typically HTTP/5985 or HTTPS/5986).
- **TLS 1.2**:<br>
  TLS 1.2 must be enabled on both the Exchange server and the system running the HelloID agent.

### Connection settings

The following user-defined global variables are used by the connector and must be configured in HelloID.

| Setting               | Description                                                   | Mandatory |
| --------------------- | ------------------------------------------------------------- | --------- |
| ExchangeConnectionUri | The PowerShell connection URI to Exchange On-Premises         | Yes       |
| ExchangeAdminUsername | The username of the service account with Exchange permissions | Yes       |
| ExchangeAdminPassword | The password of the service account (stored as secret)        | Yes       |

## Remarks

### Validation Logic

- **Display Name Validation**: The display name is checked for uniqueness across all mailboxes in Exchange. If the display name is already in use by the selected mailbox, it's considered valid. Otherwise, the form shows details of the conflicting mailbox.
- **Alias Validation**: The alias is validated for uniqueness using `Get-Recipient` with a filter that checks for matching Alias, PrimarySmtpAddress, or EmailAddresses. The validation allows the selected mailbox to keep its own alias.
- **Email Address Validation**: The email address is constructed from the mail prefix and selected domain, then validated for uniqueness across all recipients. The validation allows the selected mailbox to keep its own email address.

### Email Address Management

- **Primary vs Secondary**: Users can toggle whether the new email address should be set as the primary SMTP address (SMTP:) or added as a secondary address (smtp:). When setting as primary, any existing primary SMTP address is automatically converted to secondary.
- **Proxy Address Preservation**: The connector preserves all existing proxy addresses except when the new address already exists (to avoid duplicates). This ensures email continuity while updating the mailbox.
- **Domain Selection**: The mail domain dropdown automatically retrieves all accepted domains from Exchange and pre-selects the current domain of the mailbox for user convenience.

### Alias Field Behavior

- The alias (mailNickname) is an internal identifier separate from email addresses
- Changing the alias does not automatically update SMTP addresses
- The alias can only have one value and overwrites the previous value when changed
- Valid characters: letters, numbers, periods, hyphens, underscores (no spaces or @ symbol)

### Session Management

- **Automatic Cleanup**: The connector uses a `finally` block to ensure Exchange PowerShell sessions are properly disconnected, even if errors occur during processing.
- **Session Options**: The connector is configured with `SkipCACheck`, `SkipCNCheck`, and `SkipRevocationCheck` set to `$false` for secure connections. Adjust these settings based on your certificate configuration.

### Error Handling

- All datasources and tasks include comprehensive try-catch blocks with detailed error messages
- Error messages include the script line number and specific action being performed when the error occurred
- Audit logs are sent to HelloID for both successful operations and errors

## Development resources

### API endpoints

The connector uses the following Exchange PowerShell cmdlets:

| Cmdlet             | Description                                                   |
| ------------------ | ------------------------------------------------------------- |
| Get-Mailbox        | Retrieve mailbox information for searching and validation     |
| Get-Recipient      | Retrieve recipient information for alias and email validation |
| Get-AcceptedDomain | Retrieve accepted mail domains                                |
| Set-Mailbox        | Update mailbox properties                                     |

### API documentation

For more information on Exchange PowerShell cmdlets:

- [Connect to Exchange Servers using remote PowerShell](https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell)
- [Get-Mailbox cmdlet reference](https://learn.microsoft.com/en-us/powershell/module/exchange/get-mailbox)
- [Set-Mailbox cmdlet reference](https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailbox)
- [Get-Recipient cmdlet reference](https://learn.microsoft.com/en-us/powershell/module/exchange/get-recipient)
- [Get-AcceptedDomain cmdlet reference](https://learn.microsoft.com/en-us/powershell/module/exchange/get-accepteddomain)

## Getting help

> :bulb: **Tip:**  
> _For more information on Delegated Forms, please refer to our [documentation](https://docs.helloid.com/en/service-automation/delegated-forms.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
