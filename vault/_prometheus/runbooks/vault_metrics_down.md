# Vault metrics down

Prometheus cannot scrape `https://<instance>/v1/sys/metrics`.

## Checks

```bash
maand run_command --workers <instance> 'docker ps --filter name=vault'
curl -sk "https://<instance>:$(maand cat job_ports vault | rg vault_port_api)/v1/sys/metrics?format=prometheus" | head
```

## Recovery

1. Restart the node: `maand deploy --force --jobs vault`
2. If sealed after restart: `maand job_command vault command_unseal --verbose`
