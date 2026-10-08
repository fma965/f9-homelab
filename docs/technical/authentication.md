# Authentication & access

## Components

- **LLDAP** (`default/lldap`) stores users and groups.
- **Authelia** (`default/authelia`) is the login portal and OpenID Connect (OIDC) provider at `auth.f9.casa`. Config: `kubernetes/apps/default/authelia/app/resources/configuration.yaml`.

## Two ways an app is protected

### 1. Forward auth (`ext-auth` component)

Add the component in the app's `ks.yaml`:

```yaml
components:
    - ../../../../components/ext-auth
```

It creates an Envoy `SecurityPolicy` named after `${APP}` that targets the app's `HTTPRoute` and asks Authelia (`/api/authz/ext-authz/`) before letting a request through. Authelia then applies the `access_control` rules and passes `Remote-User`, `Remote-Groups`, `Remote-Name` and `Remote-Email` to the app.

Paperless, Home Assistant, Radarr/Sonarr/Prowlarr, qBittorrent, SABnzbd, ESPHome, Homepage and others use this. The route name must equal `${APP}`. Override with `EXT_AUTH_TARGET` if it doesn't.

### 2. OIDC (the app signs users in through Authelia)

Used by Homebox, Zipline, Open WebUI and Bambuddy. Each has an OAuth client ID/secret in 1Password and OIDC settings in its HelmRelease. The Authelia `identity_providers.oidc` section lists the clients.

Jellyfin and Home Assistant sign users in against LLDAP (LDAP), Seerr uses Jellyfin accounts, Music Assistant uses Home Assistant accounts, and Immich signs in through Authelia OIDC. All of them therefore share the same house login, even though only some sit behind forward auth.

## Access rules (Authelia)

Rules are evaluated top to bottom and the first match wins. Summary:

1. **API bypass** for the Servarr stack, Frigate and the SABnzbd `/api` paths.
2. **Admins** (`group:admin`) get two-factor access to every `*.f9.casa` site.
3. **`/code/` paths** are denied to everyone else.
4. **`help.f9.casa/technical/`** is denied to everyone else (these docs).
5. **Media management** hosts require `group:media_management`.
6. **Downloads** hosts require `group:downloads`.
7. **Home hosts** (`f9.casa`, `home`, `inventory`, `photos`, `docs`, `help`, `ai`, `cctv`, `frigate`) require `group:home`.
8. **Everything else** is denied.

Default policy is `two_factor`.

!!! danger "No source-network bypass"
    Do not add a rule that trusts internal IP ranges. Authelia reads the client IP from `X-Forwarded-For`, which a client can forge. The config notes this deliberately.

## Adding a user

1. Create the user in LLDAP and add them to groups (`home` for normal housemates).
2. They sign in at `auth.f9.casa` and enrol a second factor.
3. Nothing else is needed. Jellyfin, Seerr, Immich, Music Assistant and Home Assistant accept the same account.

## Adding a new protected site

1. Add `ext-auth` (or OIDC) to the app.
2. Add its hostname to the right Authelia rule. A hostname that matches no rule is denied for non-admins.
3. Merge. Authelia's ConfigMap changes, and reloader restarts it.
