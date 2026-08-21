# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-08-21

Initial release of HelloID-Conn-SA-Full-Exchange-On-Premises-Roommailbox-Update.

### Added

- Initial release for updating Exchange On-Premises Room Mailboxes
- Added datasource `Exchange-On-Premises-Get-Roommailbox-Wildcard-Name-Alias` to search and select room mailboxes by name, alias, or email address
- Added datasource `Exchange-On-Premises-Check-DisplayName-Unique` to validate display name uniqueness
- Added datasource `Exchange-On-Premises-Check-Alias-Unique` to validate alias uniqueness
- Added datasource `Exchange-On-Premises-Check-EmailAddress-Unique` to validate email address uniqueness
- Added datasource `Exchange-On-Premises-Get-All-MailDomains` to retrieve accepted mail domains from Exchange
- Added task `Exchange On-Premises - Roommailbox - Update` to update room mailbox properties
- Support for updating display name, alias, email address with domain dropdown, and resource capacity
- Primary email address toggle functionality to set email as primary or secondary
- Comprehensive audit logging for all operations
- Proper Exchange session management with automatic cleanup in finally block
- TLS 1.2 security protocol enforcement
- Detailed error handling with actionable error messages

### Changed

### Deprecated

### Removed

### Fixed
