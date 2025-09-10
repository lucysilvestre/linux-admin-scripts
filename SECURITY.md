# Security Policy
- Do not commit credentials, tokens, or private endpoints.
- Read sensitive values from environment variables or files outside the repo.
- If a script handles secrets, ensure permissions are restrictive (e.g., `umask 077`).