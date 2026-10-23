# oidc

Gates an HTTPRoute with the Envoy gateway's OIDC filter against Pocket ID (`id.f9.casa`) (it replaced the old Authelia forward-auth). Use it in an app's Flux Kustomization:

```yaml
components:
    - ../../../../components/oidc
dependsOn:
    - name: pocket-id
      namespace: security
postBuild:
    substitute:
        APP: <app> # HTTPRoute name, hostname <app>.f9.casa, client id
        OIDC_GROUP: admins # optional; the Pocket ID group allowed in (default admins)
        OIDC_HOST: <host> # optional; the route's hostname when it is not <app>.f9.casa
        OIDC_TARGET: <route> # optional; the HTTPRoute to gate when its name is not <app>
        OIDC_TITLE: <Name> # optional; the name people see in Pocket ID (default <app>)
        OIDC_DESCRIPTION: <one line> # optional; shown under the name
```

It creates a `PocketIDOIDCClient` named `$APP` (the Pocket ID operator registers it in Pocket ID and writes `$APP-oidc-credentials`) and a `SecurityPolicy` that redirects to Pocket ID, using the callback `https://$APP.f9.casa/oauth2/callback`. Only members of `OIDC_GROUP` get a token. Every protected app is its own Pocket ID client, so there is one login per app (passkeys keep that painless). The route must use a gateway in `network`, and have one hostname (set `OIDC_HOST` when it is not `<app>.f9.casa`: the login returns to that host, so a route with two hostnames would loop on the other). The group named in `OIDC_GROUP` must hold the admins too: Authelia let admins into every app, Pocket ID only lets in the group's members.

Non-browser callers (API keys, webhooks, health checks) are redirected to the login page too; give them a separate route or exempt the path, as radarr, prowlarr and sabnzbd do (a second `/api` route with no policy).
