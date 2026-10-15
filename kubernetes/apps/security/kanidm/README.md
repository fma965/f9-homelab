# Kanidm (id.f9.casa)

Identity provider, run by [Kaniop](https://github.com/pando85/kaniop) (`../kaniop`). It sits next to Authelia while apps are moved over one at a time; `network/echo` is the first app on it.

- **Where:** `https://id.f9.casa`, public on `envoy-external` (like Authelia, so apps on the external gateway can send people to the login page). The pod serves TLS itself with the `kanidm-tls` certificate (cert-manager); the gateway re-encrypts to it.
- **Accounts:** `name@id.f9.casa`. The domain cannot be changed later. LDAP is off; Jellyfin will use its SSO plugin.
- **People:** `app/people.yaml` defines `scott` (display name only; no email or legal name, as this repository is public) and `app/groups.yaml` makes the account a member of `admins`, which is the group the Echo client lets in. To enrol a passkey, run `kubectl -n security describe kanidmpersonaccount scott`: with no credentials defined, Kaniop prints a one-time link (valid for an hour by default, `credentialsTokenTtl`). A group's `members:` is the exact list, so anyone added by hand is removed again; add new people to `people.yaml` and to `members:`.
- **Admin logins:** the operator generates them into the `kanidm-admin-passwords` Secret (`ADMIN_*` and `IDM_ADMIN_*` keys). Read them once to store in 1Password; do not commit them.
- **Passkeys only:** a group's account policy can require passkeys (`credential-type-minimum: passkey`); Kaniop's `KanidmGroup` has an account-policy field for it.
- **Gating a route:** add `../../../../components/oidc` to the app's Flux Kustomization instead of `ext-auth` (see `kubernetes/components/oidc`).

**Not backed up yet.** Kanidm holds the accounts and passkeys. Kaniop has `KanidmBackupRepository` / `KanidmBackupSchedule` (S3, as in bjw-s-labs/home-ops); add one (a Garage bucket and a 1Password item) before moving real apps onto it.

## Branding

- **In git:** `app/resources/override.css` (colours and layout; the accent and surfaces are variables at the top) and `app/favicon.yaml` (the 48x48 favicon, the emblem cropped from `app/resources/logo.png`) are mounted over the files the server ships in `/hpkg`. Kanidm reads them at start-up, so after editing, restart the pod: `kubectl -n security rollout restart statefulset kanidm-default`.
- **In Kanidm itself (the heading and the sign-in logo are stored in its database, not in a file):**
    ```sh
    kanidm system domain set-displayname "F9 Auth" -D admin
    kanidm system domain set-image app/resources/logo.png png -D admin
    ```
    The image has to be under 256 KB and 1024x1024. The `admin` password is in `kanidm-admin-passwords` (`ADMIN_PASSWORD`). Per-app names and logos are set on each client: `displayname` in `KanidmOAuth2Client`, and `kanidm system oauth2 set-image <client> <file>` for the picture.
- **Cannot be changed:** the browser tab title (`Login`) and the "Powered by Kanidm" footer text are in the server's HTML templates.
