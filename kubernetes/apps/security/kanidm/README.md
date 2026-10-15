# Kanidm (id.f9.casa)

Identity provider, run by [Kaniop](https://github.com/pando85/kaniop) (`../kaniop`). It sits next to Authelia while apps are moved over one at a time; `network/echo` is the first app on it.

- **Where:** `https://id.f9.casa`, public on `envoy-external` (like Authelia, so apps on the external gateway can send people to the login page). The pod serves TLS itself with the `kanidm-tls` certificate (cert-manager); the gateway re-encrypts to it.
- **Accounts:** `name@id.f9.casa`. The domain cannot be changed later. LDAP is off; Jellyfin will use its SSO plugin.
- **No people are defined in this repository** (it is public). Create yourself with a local `KanidmPersonAccount` (not committed) in the `security` namespace, `kubectl apply` it, then run `kubectl -n security describe kanidmpersonaccount <name>`: with no credentials set, Kaniop prints a one-time link to enrol a passkey. Add the person to a group (`admins`) from `groups.yaml` (`members:`) or with the Kanidm CLI.
- **Admin logins:** the operator generates them into the `kanidm-admin-passwords` Secret (`ADMIN_*` and `IDM_ADMIN_*` keys). Read them once to store in 1Password; do not commit them.
- **Passkeys only:** a group's account policy can require passkeys (`credential-type-minimum: passkey`); Kaniop's `KanidmGroup` has an account-policy field for it.
- **Gating a route:** add `../../../../components/oidc` to the app's Flux Kustomization instead of `ext-auth` (see `kubernetes/components/oidc`).

**Not backed up yet.** Kanidm holds the accounts and passkeys. Kaniop has `KanidmBackupRepository` / `KanidmBackupSchedule` (S3, as in bjw-s-labs/home-ops); add one (a Garage bucket and a 1Password item) before moving real apps onto it.
