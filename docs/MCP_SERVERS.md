# MCP Servers Configuration

This document describes the team-standard MCP servers for ProtoGen Claude Code workflows.

## Standard MCP Servers

These MCPs are included in the `templates/.claude.json.template` file.

### 1. HoloViz MCP
**Purpose:** Access Panel, hvPlot, HoloViews, and other HoloViz ecosystem documentation.

```json
"holoviz": {
  "type": "stdio",
  "command": "uvx",
  "args": ["holoviz-mcp"],
  "env": {}
}
```

**Installation:** `uvx holoviz-mcp` (automatically downloads on first use)

### 2. Context7 MCP
**Purpose:** General library documentation lookup for any Python/JavaScript library.

```json
"context7": {
  "type": "http",
  "url": "https://mcp.context7.com/mcp"
}
```

**Installation:** No installation needed (HTTP-based).

### 3. Playwright MCP
**Purpose:** Browser automation for testing and web scraping.

```json
"playwright": {
  "type": "stdio",
  "command": "cmd",
  "args": ["/c", "npx", "@playwright/mcp@latest"],
  "env": {}
}
```

**Installation:** `npx @playwright/mcp@latest` (automatically downloads on first use)

### 4. Material UI MCP
**Purpose:** Material UI/MUI documentation for React components.

```json
"mui-mcp": {
  "type": "stdio",
  "command": "cmd",
  "args": ["/c", "npx", "-y", "@mui/mcp@latest"],
  "env": {}
}
```

**Installation:** `npx -y @mui/mcp@latest` (automatically downloads on first use)

---

## ProtoGen Database MCPs

These MCPs provide direct SQL access to ProtoGen databases. **Requires custom setup per user.**

### Prerequisites

1. **Install mcp-postgres server:**
   ```bash
   git clone <mcp-postgres-repo-url> ~/Documents/mcp-postgres
   cd ~/Documents/mcp-postgres
   pip install -r requirements.txt
   ```

2. **Get database credentials:**
   - Request credentials from DevOps or team lead
   - Credentials vary by database (dev/staging/prod)

### Configuration

Add to your `~/.claude.json` (NOT the template):

```json
"postgres": {
  "type": "stdio",
  "command": "python",
  "args": [
    "C:\\Users\\YOUR_USERNAME\\Documents\\mcp-postgres\\postgres_server.py",
    "--conn",
    "postgresql://USER:PASSWORD@HOST:PORT/protogen_rw_stage"
  ],
  "env": {}
},
"protogen_rw": {
  "type": "stdio",
  "command": "python",
  "args": [
    "C:\\Users\\YOUR_USERNAME\\Documents\\mcp-postgres\\postgres_server.py",
    "--conn",
    "postgresql://USER:PASSWORD@HOST:PORT/protogen_rw"
  ],
  "env": {}
},
"protogen_rw_dev": {
  "type": "stdio",
  "command": "python",
  "args": [
    "C:\\Users\\YOUR_USERNAME\\Documents\\mcp-postgres\\postgres_server.py",
    "--conn",
    "postgresql://USER:PASSWORD@HOST:PORT/protogen_rw_dev"
  ],
  "env": {}
}
```

**Replace:**
- `YOUR_USERNAME` - Your Windows username
- `USER` - Database username (usually `postgres`)
- `PASSWORD` - Database password (obtain from team)
- `HOST` - Database host IP
- `PORT` - Database port (usually `5432`)

### Database Descriptions

| MCP Name | Database | Purpose |
|----------|----------|---------|
| `postgres` | `protogen_rw_stage` | Staging environment - safe for testing |
| `protogen_rw` | `protogen_rw` | Production database - use with caution |
| `protogen_rw_dev` | `protogen_rw_dev` | Development database - most frequently updated |

### Security Considerations

⚠️ **IMPORTANT:**
- **Never commit database credentials to git**
- Keep credentials in `~/.claude.json` (gitignored)
- Do not add credentials to the template file
- Use read-only credentials when possible
- Avoid SELECT * queries on large tables

### Verification

Test your MCP connections:

```bash
# List all MCPs and their status
claude mcp list

# Test specific MCP
claude mcp test postgres
claude mcp test protogen_rw_dev
```

---

## Troubleshooting

### MCP Not Connecting

```bash
# Check logs
claude mcp logs holoviz
claude mcp logs postgres

# Remove and re-add
claude mcp remove holoviz
claude mcp add holoviz -- uvx holoviz-mcp
```

### Permission Issues

If Claude Code cannot access an MCP tool:
1. Check `allowedTools` in `~/.claude.json`
2. Grant permission when prompted
3. Or manually add to allowed tools list

### Database Connection Errors

Common issues:
- **Timeout:** Check VPN connection or IP whitelist
- **Authentication failed:** Verify username/password
- **Database does not exist:** Check database name spelling
- **SSL error:** May need to add `?sslmode=require` to connection string

---

## Adding New MCPs

To propose a new team-standard MCP:

1. Test locally in your `~/.claude.json`
2. Document the MCP purpose and setup
3. Create PR to add to `templates/.claude.json.template`
4. Update this documentation

---

## Questions?

Contact the DevOps team or post in #claude-code-help Slack channel.
