# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-04

### Added
- Regex origin matching support (e.g., `/\.example\.com$/`)
- `expose_headers` option for `Access-Control-Expose-Headers`
- GitHub issue template gem version field
- Feature request "Alternatives considered" field

## [0.1.5] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.4] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.3] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.2] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes
- Remove inline comments from Development section to match template

## [0.1.1] - 2026-03-22

### Changed
- Expand test coverage

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Rack-compatible CORS middleware
- Configurable allowed origins with wildcard support
- Preflight OPTIONS request handling
- Custom allowed methods and headers
- Credentials support with proper origin echoing
- Configurable max-age for preflight caching
- Vary header for specific-origin configurations
