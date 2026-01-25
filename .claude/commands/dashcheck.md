---
allowed-tools: Bash(*), Read(*), TodoWrite
description: Smoke test all ProtoGen dashboards and report startup timing
---

# Dashboard Health Check

Run smoke tests on all ProtoGen Panel dashboards to verify they load successfully and capture performance timing.

## Dashboards to Check

| Dashboard | Repo | Branch | Entry Point | Port | Conda Env |
|-----------|------|--------|-------------|------|-----------|
| dash | dash | dev | `src/pg_dash/pg_dash.py` | 5006 | pg_dash_env |
| batch_reopt | batch_reopt | main | `src/batch_reopt/app.py` | 5009 | batch_reopt_env |
| sandbox_dash | sandbox_dash | main | `src/sandbox_dash/sandbox_dash.py` | 5010 | sandbox_dash_env |
| pv_viz | pv_viz | main | `src/pv_viz/app.py` | 5011 | pv_viz_env |
| circuit_viz | circuit_viz | main | `src/circuit_viz/app.py` | 5008 | circuit_viz_env |

## Instructions

For each dashboard:

1. Kill any existing panel serve processes on the target port
2. Activate the correct conda environment using:
   ```bash
   source /c/Users/AdamMorse/anaconda3/etc/profile.d/conda.sh && conda activate <env_name>
   ```
3. Navigate to the repo directory under `C:\Users\AdamMorse\Documents\`
4. Run `panel serve <entry_point> --port <port>` in background, redirecting output to a temp log file
5. Wait for Bokeh server to start (check for "Bokeh app running at" in log)
6. Trigger a connection with `curl -s http://localhost:<port>/<app_name> > /dev/null 2>&1 &`
7. Wait up to 60 seconds for `SERVER_READY` to appear in the log
8. Parse the timing values from the log
9. Kill the panel serve process
10. Record success/failure and timing

## Expected Log Format

```
MM-DD HH:MM:SS | INFO | app | SERVER_READY | startup=X.XXs | imports=X.XXs | extensions=X.XXs | configure=X.XXs
```

Note: SERVER_READY is logged when a client first connects (Panel uses lazy loading).

## App Names for curl

- dash: `/pg_dash`
- batch_reopt: `/app`
- sandbox_dash: `/sandbox_dash`
- pv_viz: `/app`
- circuit_viz: `/app`

## Output

After checking all dashboards, report results in a markdown table:

```markdown
| Dashboard | Status | Startup | Imports | Extensions | Configure |
|-----------|--------|---------|---------|------------|-----------|
| dash | OK | 8.26s | 6.91s | 1.35s | 0.00s |
| batch_reopt | OK | 8.03s | 8.00s | 0.03s | 0.01s |
| sandbox_dash | OK | 1.09s | 0.85s | 0.19s | 0.04s |
| pv_viz | OK | 11.92s | 11.92s | 0.00s | 0.00s |
| circuit_viz | OK | 9.76s | 1.94s | 1.66s | 6.16s |
```

If any dashboard fails to start within 60 seconds, mark as FAIL and note the issue.

## Example Command Pattern

```bash
# Start dashboard
source /c/Users/AdamMorse/anaconda3/etc/profile.d/conda.sh && \
conda activate pg_dash_env && \
cd /c/Users/AdamMorse/Documents/dash && \
panel serve src/pg_dash/pg_dash.py --port 5006 > /tmp/dash_output.log 2>&1 &

# Wait for server to start
sleep 5

# Trigger connection to load the app
curl -s http://localhost:5006/pg_dash > /dev/null 2>&1 &

# Wait for SERVER_READY (up to 60 seconds)
sleep 45

# Check output
cat /tmp/dash_output.log | grep SERVER_READY

# Kill the process
taskkill //F //PID <pid>
```

## Important Notes

- Always use the correct conda environment - using base env results in 3-4x slower startup times
- SERVER_READY appears after a client connects, not when the Bokeh server starts
- Use unique ports to avoid conflicts
- dash repo uses `dev` branch, all others use `main`
- If SERVER_READY is not found, check for errors in stdout/stderr

## Execute

Run the health check now. Track progress using TodoWrite.
