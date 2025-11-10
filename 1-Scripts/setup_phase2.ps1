# Create directories
New-Item -ItemType Directory -Path "automation\workflows" -Force | Out-Null

# Write command_map.json
@'
{
  "run_audit": "/webhook/run_audit",
  "open_pr": "/webhook/open_pr"
}
'@ | Set-Content -Encoding UTF8 "automation\command_map.json"

# Write run_audit.json
@'
[
  {
    "name": "Run Audit Webhook",
    "type": "Webhook",
    "url": "/webhook/run_audit",
    "method": "POST",
    "auth": "None",
    "body": { "parse": "JSON" },
    "onFail": "Send to DLQ"
  },
  {
    "name": "Check Idempotency",
    "type": "Code",
    "script": "if (await checkIfRunExists(run_id)) throw new Error('Duplicate run');"
  },
  {
    "name": "Hash Inputs",
    "type": "Function",
    "script": "inputs_hash = hash(JSON.stringify($json.args));"
  },
  {
    "name": "Call Local LLM (Optional)",
    "type": "HTTP Request",
    "url": "http://localhost:11434/api/generate",
    "method": "POST",
    "body": { "prompt": "Run audit for: " + $json.args.area },
    "optional": true
  },
  {
    "name": "Generate Log File",
    "type": "Function",
    "script": "writeLog(run_id, {...});"
  },
  {
    "name": "Return Output",
    "type": "Respond to Webhook",
    "response": {
      "ok": true,
      "run_id": "$json.run_id",
      "summary": "Audit run completed",
      "artifacts": ["2-Logs/run_....md", "2-Logs/run_....json"]
    }
  },
  {
    "name": "Send to DLQ",
    "type": "Queue",
    "queue": "DLQ_run_audit"
  }
]
'@ | Set-Content -Encoding UTF8 "automation\workflows\run_audit.json"

# Write open_pr.json
@'
[
  {
    "name": "Open PR Webhook",
    "type": "Webhook",
    "url": "/webhook/open_pr",
    "method": "POST",
    "auth": "None",
    "body": { "parse": "JSON" },
    "onFail": "Send to DLQ"
  },
  {
    "name": "Check Idempotency",
    "type": "Code",
    "script": "if (await checkIfPRExists(branch)) throw new Error('Duplicate PR');"
  },
  {
    "name": "Create Branch",
    "type": "Shell",
    "script": "git checkout -b $json.branch"
  },
  {
    "name": "Write Files",
    "type": "Function",
    "script": "decodeAndWriteFiles($json.changes)"
  },
  {
    "name": "Commit Changes",
    "type": "Shell",
    "script": "git add . && git commit -m 'Add PR artifacts'"
  },
  {
    "name": "Push + Open PR",
    "type": "HTTP Request",
    "url": "https://api.github.com/repos/<owner>/<repo>/pulls",
    "method": "POST",
    "auth": "GitHub Secrets",
    "body": {
      "title": "Fix: " + $json.branch,
      "head": "$json.branch",
      "base": "main",
      "body": "decode($json.pr_body_md_base64)"
    }
  },
  {
    "name": "Return PR Status",
    "type": "Respond to Webhook",
    "response": {
      "ok": true,
      "pr_url": "$json.pr_url",
      "ci_status": "pending"
    }
  },
  {
    "name": "Send to DLQ",
    "type": "Queue",
    "queue": "DLQ_open_pr"
  }
]
'@ | Set-Content -Encoding UTF8 "automation\workflows\open_pr.json"

Write-Host "✅ All files created under automation\workflows\"
