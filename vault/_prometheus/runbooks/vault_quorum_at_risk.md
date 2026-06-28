# Vault quorum at risk

Fewer than 2 vault nodes are scrapeable. Raft needs a majority to elect a leader.

## Checks

```bash
maand cat allocations --jobs vault
maand job_command vault command_cluster_status
maand job_command vault command_unseal --verbose
```

## Recovery

Bring failed nodes back with `maand deploy --force --jobs vault`, then unseal each sealed node.
