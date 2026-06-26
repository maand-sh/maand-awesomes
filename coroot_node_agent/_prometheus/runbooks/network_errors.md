# Network Errors

## Alerts

- `NetworkReceiveErrors` — NIC is receiving packets with errors
- `NetworkTransmitErrors` — NIC is transmitting packets with errors

## Impact

Network errors indicate hardware faults, misconfigured MTU, or bad cabling/switches. Even a low error rate can cause TCP retransmissions, increased latency, and packet loss — impacting all services on the node.

## Diagnosis

### Check interface error counters

```bash
ip -s link show
# or
netstat -s | grep -i error
```

### Identify the affected interface

```bash
cat /proc/net/dev
```

### Check interface speed and duplex (duplex mismatch is a common cause)

```bash
ethtool <interface>   # e.g. ethtool eth0
```

### Check for dropped packets

```bash
ip -s link show <interface>
```

### Check kernel logs for hardware errors

```bash
dmesg | grep -iE "eth|nic|link|error|reset" | tail -30
journalctl -k | grep -iE "eth|nic|link|error" | tail -30
```

## Remediation

### 1. Restart the network interface

```bash
ip link set <interface> down && ip link set <interface> up
```

### 2. Force speed/duplex to match the switch

```bash
ethtool -s <interface> speed 1000 duplex full autoneg off
```

### 3. Check and fix MTU mismatch

```bash
ip link set <interface> mtu 1500
```

### 4. Replace the cable or switch port if hardware fault is suspected

Contact the data-centre or cloud provider if running on bare metal with persistent errors.

## Escalation

If errors persist after interface restart and no configuration issue is found, escalate to the networking/infrastructure team and open a ticket with the cloud provider (attach `dmesg` output and error counter snapshots).
