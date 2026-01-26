# Changelog

All notable changes to the ProtoGen Claude Code Workflow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
- **WebSearch Tool Access** (2026-01-26): Added `WebSearch` to the allowed tools list in both PowerShell and Bash workflow scripts. Previously, only `WebFetch` was included, which prevented Claude from performing web searches even in permissionless mode. This fix enables Claude to search the web for up-to-date information, documentation, and current events.
  - Updated: `scripts/powershell/claude-aliases.ps1` (both `cc` and `ccw` functions)
  - Updated: `scripts/bash/claude-aliases.sh` (both `cc` and `ccw` functions)

## [1.0.0] - 2026-01-26

### Added
- Initial release of ProtoGen Claude Code Workflow
- Slash commands for issue management, GitHub Projects integration, and workflow automation
- PowerShell and Bash workflow functions (`cc`, `ccw`, `prv`, `pr-done`, etc.)
- GitHub Projects configuration for Grid Nav board (`.claude-project-config.yml`)
- Documentation: Setup Guide, Workflow Guide, Command Reference, MCP Servers, Migration Guide
- Templates for settings and profiles
