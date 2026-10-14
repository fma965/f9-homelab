# Matter server

matter-server (matterjs) runs on the NoT VLAN (`not` NAD, macvlan). The Thread border router is the SLZB-MR1U
(OTBR REST at `http://zigbee-controller.not.internal:8080`). Matter WS URL:
`ws://matter-server.default.svc.cluster.local:5580/ws`.

> [!WARNING]
> **Adding a Matter device to NoT needs temporary UniFi changes, and they MUST be reverted afterwards.**
> The firewall and Wi-Fi settings are in UniFi, not in this repo, so nothing here will remind you.
> Do the checklist below, then revert everything in [Put it back](#put-it-back-after-pairing).

## Pairing a new device (Android)

Do all of this **with the phone on the `F9 (NoT)` SSID**, not `F9` (Main). Main has no IPv6 and no route to the
Thread prefix, so it fails at "Checking connectivity to Thread network".

### Temporary changes needed first

| #   | Change (UniFi)                                                                                                                         | Why                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| --- | -------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Turn OFF client isolation (L2 isolation)** on the `F9 (NoT)` WLAN (Settings > WiFi > F9 (NoT) > Advanced > Client Device Isolation)  | With it on, the phone cannot reach a new **Wi-Fi** Matter device on the same SSID. Pairing hangs forever at **"Checking network connectivity to F9 (NoT)"**. Thread devices are not affected, because the phone only needs the wired SLZB.                                                                                                                                                                                                     |
| 2   | **Create a firewall policy "TEMP Phone (\<model\>) NoT to Internet"**: NoT zone, source = the phone's client MAC, destination External | **Not proven to be required.** On 14 Oct 2026 this was enabled at the same time as change 1 and pairing then worked, so only change 1 is confirmed. Try without it first. NoT has internet access off. The Google Play Services / Google Home steps ("Generating Matter credentials", the connectivity check) need the phone to reach Google. Scope it to the phone's MAC only. Create it with `create_allow_respond` off or UniFi rejects it. |
| 3   | Only if pairing stalls at "Resolving (no address known)": enable mDNS reflection for NoT (and IoT if the device is there)              | The phone and matter-server must find the device by mDNS.                                                                                                                                                                                                                                                                                                                                                                                      |

The phone's NoT MAC is a private (randomised) MAC and stays the same for that SSID. Check it in UniFi Clients.

### Permanent rules that are already in place (do not remove)

- **Allow NoT** (NoT -> NoT): the phone, matter-server, HA and devices share the VLAN.
- **Allow Return Traffic (HomeLab to NoT)**: Envoy LB IPs are announced from HomeLab nodes.
- **NoT to Envoy Gateway** (NoT -> Services IP group, TCP/UDP 443): the Home Assistant app on NoT reaches HA through the gateway.
  Mirrors the IoT / Media / VPN rules.
- **Allow NoT to MQTT**, **Allow NoT to NAS for NTP**.

### Put it back after pairing

1. **Turn client isolation back ON** for `F9 (NoT)`.
2. **Delete** the `TEMP Phone ... NoT to Internet` policy.
3. Turn mDNS reflection back off for NoT / IoT if you enabled it.
4. In UniFi, confirm `TEMP Allow NOT to Services` and `TEMP ALLOW AINTERNET` are still **disabled**.

If you pair several devices in a row, leave 1 and 2 until the last one, but do not forget them.

## Android gotchas

- The Android HA flow pairs **twice** by design: the phone / Play Services fabric first, then matter-server as a
  second admin. If the HA stage stalls at "Resolving (no address known)" the device ends up only in the phone's
  fabric. Retrying from the phone worked eventually.
- After any OTBR channel or network change, reload the HA `otbr` config entry (HA's stored dataset goes stale), then run
  **Sync Thread credentials** in the companion app.
- Old SLZB firmware ignored `PUT /node/dataset/pending` and `DELETE /node` wiped the OTBR state. Current firmware is fine.
- matterjs 1.4.0 ignores `THREAD_REST_PROBE_PORT` and still probes OTBR on `:8081`.

## Quick diagnosis

| Stuck at                                      | Likely cause                                                                       |
| --------------------------------------------- | ---------------------------------------------------------------------------------- |
| Checking connectivity to **Thread** network   | Phone is on `F9` (Main), not `F9 (NoT)`                                            |
| Checking network connectivity to **F9 (NoT)** | Client isolation still on (change 1). Possibly no internet on the phone (change 2) |
| Generating Matter credentials                 | Phone cannot reach Google (change 2)                                               |
| Resolving (no address known)                  | mDNS not reaching the device (change 3), or retry from the phone                   |

Useful checks: `curl http://zigbee-controller.not.internal:8080/node/state` should say `leader`, and UniFi traffic flows
filtered by the phone's IP show whether anything is blocked.
