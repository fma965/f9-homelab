# oidc

Gates an HTTPRoute with the Envoy gateway's OIDC filter against Kanidm (`id.f9.casa`), as an alternative to `ext-auth` (Authelia forward-auth). Use it in an app's Flux Kustomization:

```yaml
components:
    - ../../../../components/oidc
dependsOn:
    - name: kanidm
      namespace: security
postBuild:
    substitute:
        APP: <app> # HTTPRoute name, hostname <app>.f9.casa, client id
        OIDC_GROUP: admins # optional; the Kanidm group allowed in (default admins)
```

It creates a `KanidmOAuth2Client` named `$APP` (Kaniop registers it in Kanidm and writes `$APP-kanidm-oauth2-credentials`) and a `SecurityPolicy` that redirects to Kanidm, using the callback `https://$APP.f9.casa/oauth2/callback`. Only members of `OIDC_GROUP` get a token. Every protected app is its own Kanidm client, so there is one login per app (passkeys keep that painless). The route must use a gateway in `network` and a hostname of the form `<app>.f9.casa`.

Non-browser callers (API keys, webhooks, health checks) are redirected to the login page too; give them a separate route or exempt the path, as the `ext-auth` apps do today.
