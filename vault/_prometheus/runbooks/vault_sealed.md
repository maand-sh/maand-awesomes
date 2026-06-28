# Vault sealed

The node is running but `vault_core_unsealed == 0`.

## Recovery

```bash
maand job_command vault command_unseal --verbose
```

If unseal keys are missing from KV, see the recovery steps in `command_node_up` (clear `./data`, reset secrets/vars, redeploy).
