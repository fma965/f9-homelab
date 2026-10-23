# Pocket ID (id.f9.casa)

Identity provider (passkeys only), run by the [Pocket ID operator](https://github.com/aclerici38/pocket-id-operator) (`operator/`). It replaced Kanidm and is the login for the cluster: apps that do OIDC use a `PocketIDOIDCClient`, and routes without a login of their own use the `oidc` component (`oidc-claims` adds `Remote-User` headers for apps that need them).

- **Where:** `https://id.f9.casa`, public on `envoy-external` (so apps on the external gateway can send people to the login page). The operator creates the HTTPRoute from `spec.route` in `app/instance.yaml`.
- **Declarative:** the instance (`app/instance.yaml`), users (`app/users.yaml`), groups (`app/groups.yaml`) and each app's client (`kubernetes/components/oidc`) are resources the operator reconciles into Pocket ID. A group's `users.userRefs` adds to the group; members added by hand in the UI are not removed. Deleting a `PocketIDUser` does not delete the user in Pocket ID (so passkeys are not lost by accident).
- **First login:** `kubectl -n security get pocketiduser scott -o jsonpath='{.status.oneTimeLoginURL}'` prints a one-time link (valid for an hour) to register the first passkey.
- **Secrets:** 1Password item `pocket-id`: `ENCRYPTION_KEY` (encrypts the instance's keys in its database; never change it once data exists, and keep it as long as the oldest backup) and `SCOTT_EMAIL` (the email of the `scott` user; Pocket ID requires one and this repository is public). `app/externalsecret.yaml` pulls both.
- **Data:** SQLite on the `pocket-id` PVC (1Gi, `ceph-block`), created by the `kopiur/backup` component and backed up hourly. The mover runs as the instance's user (`KOPIUR_PUID`/`KOPIUR_PGID` 65534 in `ks.yaml`).
- **Mail:** login and verification mail goes through `network/smtp-relay` (`egress.cilium.io/smtp-relay` label on the instance).
- **Adding a person:** a `PocketIDUser` (name, `userInfoSecretRef` with `username`, `firstName`, `email`, `displayName`), and add it to the groups it needs.
- **Gating a route:** add `../../../../components/oidc` to the app's Flux Kustomization (see `kubernetes/components/oidc`).
- **Branding:** `ui.appName` in `app/instance.yaml`; the logo and colours are set in the Pocket ID admin UI. `autoGenerateLogos` is off on the operator because it would need internet access; set `spec.logoUrl` on a client for an icon.
