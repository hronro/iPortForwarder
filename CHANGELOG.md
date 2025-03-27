# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Upgrade Rust to v1.85 in CI.

### Fixed
- Fix loading configuration file on startup.

## [1.0.0]

### Added
- [CHANGELOG.md](https://github.com/hronro/iPortForwarder/blob/master/CHANGELOG.md). All the notable changes will be documented in this file from this release.
- Enable [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox) for better security.
- Allow using domain names (previously only IP addresses were allowed). When input in a valid IPv4/Ipv6 address, an icon will be shown to indicate the type of the input.
- Check for updates upon app startup.

### Changed

- Upgrade Rust to v1.84.0 in CI.
- Remove Rust dependency `once_cell` and use Rust standard library instead, which helps reducing binary size.
- Better DMG file packaging, by using JavaScript-based [create-dmg](https://github.com/sindresorhus/create-dmg).
- Migrate to Swift 6 and Xcode 16.2
- Re-implement the "Launch at Login" feature by calling the `ServiceManagement` API directly instead of using `LaunchAtLogin` library. Now "Launch at Login" feature requires macOS 13.
