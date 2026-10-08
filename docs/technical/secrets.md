# Secrets

All secrets live in **1Password** and are never committed.

## Kubernetes

External Secrets reads 1Password through `ClusterSecretStore/onepassword-connect`. Each app declares an `ExternalSecret`:

```yaml
spec:
    secretStoreRef:
        kind: ClusterSecretStore
        name: onepassword-connect
    target:
        name: myapp-secret
        template:
            data:
                SOME_ENV: "{{ .FIELD_NAME_IN_1PASSWORD }}"
    dataFrom:
        - extract:
              key: myapp # the 1Password item name
```

Fields from every `extract` item are available to the template, so one secret can combine app fields with shared ones (`cloudnative-pg`, `authelia`, `llamacpp`).

The pod then reads it with `envFrom` or `secretKeyRef`. With `reloader.stakater.com/auto`, changing the 1Password value restarts the pod.

## Docker host

`.doco-cd.yaml` entries have `external_secrets:` mapping environment variable names to `op://vault/item/field`. Doco-CD resolves them and Compose interpolates `${VAR}`.

```yaml
external_secrets:
    CUPS_ADMIN_PASSWORD: op://kubernetes/cups/ADMIN_PASSWORD
```

## Other places

- Talos config uses `op://` references resolved with `op inject` at render time.
- GitHub Actions load secrets with the 1Password action using a service account token.
