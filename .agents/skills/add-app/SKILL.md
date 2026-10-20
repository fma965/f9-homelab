---
name: add-app
description: Use when deploying a new application to the cluster — scaffolding a Flux Kustomization plus app-template HelmRelease under kubernetes/apps/ (new app, new service, "add X to the cluster")
---

# Add a New Application

Scaffolds `kubernetes/apps/<namespace>/<app>/` with a Flux Kustomization (`ks.yaml`) and an app-template HelmRelease. Every value below comes from current repo conventions; when in doubt, mirror a real neighbouring app instead of inventing structure:

| Reference app                      | Shows                                                                                         |
| ---------------------------------- | --------------------------------------------------------------------------------------------- |
| `kubernetes/apps/default/help`     | Stateless app, multiple containers, config from a ConfigMap, public route behind `ext-auth`   |
| `kubernetes/apps/default/zipline`  | Postgres (`init-db`), ExternalSecret, NFS media with `zeroscaler`, OIDC login, network policy |
| `kubernetes/apps/default/jellyfin` | kopiur-backed persistence, GPU component, dependencies                                        |
| `kubernetes/apps/default/seerr`    | Small app with an ExternalSecret and a network policy                                         |
| `kubernetes/apps/mcp/ha-mcp`       | Public MCP server: API-key `SecurityPolicy` (`apikey.yaml`) and a network policy              |

## Step 1: Gather details

Ask the user for anything not already given:

1. **App name** and **namespace** (existing folders: `ls kubernetes/apps/`). Home and household apps go in `default`, the owner's own dev projects in `webdev`, MCP servers in `mcp`.
2. **Image** repository + tag (upstream's current release; never from memory).
3. **Port** the app listens on, and whether it gets a **route**: `envoy-internal` (default; admin and management tools) or `envoy-external` (public). Public routes without a login of their own need `ext-auth`.
4. **Persistence**: does the app store state? Local state → kopiur backup component. Files on the NAS → an NFS mount (then the `zeroscaler` component).
5. **Secrets**: env vars from 1Password → ExternalSecret. Get the 1Password item name AND its exact field names; never guess them.
6. **Database**: a Postgres database on the shared `postgres17` cluster, or Dragonfly (Redis)?
7. **Config files**: mounted config → `configMapGenerator` + `resources/`.
8. **Dependencies**: other Flux Kustomizations this app needs (`cloudnative-pg` in `database`, `csi-driver-nfs` in `kube-system`, ...).
9. **Who calls it / what it calls**, for the network policy (Step 4).

## Step 2: Create the files

```
kubernetes/apps/<namespace>/<app>/
├── ks.yaml
└── app/
    ├── kustomization.yaml
    ├── ocirepository.yaml
    ├── helmrelease.yaml
    ├── externalsecret.yaml      # only if secrets
    ├── networkpolicy.yaml       # see Step 4
    └── resources/               # only if config files
```

### ks.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/kustomize.toolkit.fluxcd.io/kustomization_v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
    name: &app <app>
spec:
    interval: 1h
    path: ./kubernetes/apps/<namespace>/<app>/app
    prune: true
    sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
    targetNamespace: <namespace>
    wait: false
```

Keys are alphabetical (see `.agents/instructions/sorting.instructions.md`). Neighbouring apps set `wait: false` explicitly; do the same. Use `wait: true` only when another Kustomization will `dependsOn` this one and this one defines no `healthChecks`.

Add `components`, `dependsOn` and `postBuild` when needed. `postBuild.substitute.APP: *app` is required whenever a component is used:

```yaml
spec:
    components:
        - ../../../../components/ext-auth # public route with no login of its own
        - ../../../../components/kopiur/backup # app keeps state on a ceph-block PVC
        - ../../../../components/zeroscaler # app mounts NFS from the NAS (scales to 0 when the NAS is down)
    dependsOn:
        - name: cloudnative-pg # uses the shared Postgres
          namespace: database
        - name: csi-driver-nfs # mounts NFS
          namespace: kube-system
    postBuild:
        substitute:
            APP: *app
            # Optional kopiur overrides, only when the defaults do not fit
            # (defaults: KOPIUR_CAPACITY 5Gi, KOPIUR_ACCESSMODES ReadWriteOnce, KOPIUR_STORAGECLASS ceph-block,
            #  KOPIUR_PUID/KOPIUR_PGID 1000; the PVC is named after the app):
            # KOPIUR_CAPACITY: 10Gi
```

Other components: `gpu` (Intel GPU claim, see jellyfin) and `alerts` (already applied per namespace). `ext-auth` creates an Authelia `SecurityPolicy` named `${APP}` targeting the route of the same name; use `EXT_AUTH_TARGET` if the route is named differently.

### app/kustomization.yaml

```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
    - ./externalsecret.yaml # only if secrets
    - ./helmrelease.yaml
    - ./networkpolicy.yaml # see Step 4
    - ./ocirepository.yaml
```

**If the app mounts config files**, put them in `resources/` and append:

```yaml
configMapGenerator:
    - name: <app>-configmap
      files:
          - config.yaml=./resources/config.yaml
generatorOptions:
    disableNameSuffixHash: true
    annotations:
        kustomize.toolkit.fluxcd.io/substitute: disabled
```

### app/ocirepository.yaml

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/source.toolkit.fluxcd.io/ocirepository_v1.json
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
    name: <app>
spec:
    interval: 10m
    layerSelector:
        mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
        operation: copy
    ref:
        tag: <version>
    url: oci://ghcr.io/bjw-s-labs/helm/app-template
```

**Never hardcode `<version>` from memory**; use the version the rest of the repo is on:

```bash
grep -h "tag:" kubernetes/apps/*/*/app/ocirepository.yaml | sort | uniq -c | sort -rn | head -1
```

### app/helmrelease.yaml

```yaml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s-labs/helm-charts/main/charts/other/app-template/schemas/helmrelease-helm-v2.schema.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
    name: <app>
spec:
    interval: 1h
    chartRef:
        kind: OCIRepository
        name: <app>
    values:
        controllers:
            <app>:
                annotations:
                    reloader.stakater.com/auto: "true"
                containers:
                    app:
                        image:
                            repository: <image-repo>
                            tag: <image-tag>
                        probes:
                            liveness:
                                enabled: true
                            readiness:
                                enabled: true
                        securityContext:
                            allowPrivilegeEscalation: false
                            readOnlyRootFilesystem: true
                            capabilities: { drop: ["ALL"] }
                        resources:
                            requests:
                                cpu: 10m
                            limits:
                                memory: 256Mi
        defaultPodOptions:
            securityContext:
                runAsNonRoot: true
                runAsUser: 1000
                runAsGroup: 1000
                fsGroup: 1000
                fsGroupChangePolicy: OnRootMismatch
        service:
            app:
                ports:
                    http:
                        port: &port <port>
```

Adjust `runAsUser`/`runAsGroup` (and capabilities) to what the image requires; drop the pod `securityContext` only if the image genuinely cannot run non-root. Plain image tags are fine, Renovate pins digests and manages updates. Namespaces enforce Pod Security `baseline` (no hostPath, no extra capabilities, no privileged).

**Route** (web UI/API), under `values` after `service`:

```yaml
route:
    app:
        annotations:
            gatus.home-operations.com/endpoint: |-
                conditions: ["[STATUS] == any(200,401)"]
            gethomepage.dev/enabled: "true"
            gethomepage.dev/group: <Homepage group, as neighbours use>
            gethomepage.dev/name: <Display name>
            gethomepage.dev/description: "<one line>"
            gethomepage.dev/icon: <icon>
        hostnames:
            - <app>.f9.casa
        parentRefs:
            - name: envoy-internal # envoy-external only for apps that must be public
              namespace: network
        rules:
            - backendRefs:
                  - name: *app
                    port: *port
```

The `*app` anchor needs `&app` on the HelmRelease `metadata.name` (as zipline does). For admin tools, state "(admin)" in the Homepage description as neighbours do.

**Persistence** under `values`:

```yaml
persistence:
    data:
        existingClaim: <app> # the kopiur PVC is named after the app
        globalMounts:
            - path: /data
    tmpfs: # writable /tmp for readOnlyRootFilesystem
        type: emptyDir
        globalMounts:
            - path: /tmp
    media: # files on the NAS (also add components/zeroscaler and the csi-driver-nfs dependency)
        type: nfs
        server: nas.main.internal
        path: /mnt/<pool>/<dataset>
        globalMounts:
            - path: /media
```

With kopiur persistence also keep `fsGroup: 1000` and `fsGroupChangePolicy: OnRootMismatch` in the pod security context.

**Config file mount** (pairs with the `configMapGenerator`):

```yaml
config:
    type: configMap
    name: <app>-configmap
    globalMounts:
        - path: /config/config.yaml
          subPath: config.yaml
          readOnly: true
```

**Secrets**: add to the container `envFrom: [{ secretRef: { name: <app>-secret } }]`.

**Postgres**: add an `init-db` initContainer (`ghcr.io/home-operations/postgres-init`, `envFrom` the app secret) that creates the database and user, as zipline does. The host is `postgres-rw.database.svc.cluster.local`. Dragonfly is `dragonfly.database.svc.cluster.local:6379`.

### app/externalsecret.yaml (only if secrets)

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.home-operations.com/external-secrets.io/externalsecret_v1.json
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
    name: <app>
spec:
    secretStoreRef:
        kind: ClusterSecretStore
        name: onepassword-connect
    target:
        name: <app>-secret
        template:
            data:
                SOME_ENV_VAR: "{{ .FIELD_NAME_IN_1PASSWORD }}"
    dataFrom:
        - extract:
              key: <1password-item>
```

`metadata.name` is `<app>`, the generated Secret is `<app>-secret`, and `template.data` references the item's real field names (from Step 1); a wrong name renders an empty value with no error. Several items can be listed under `dataFrom` (zipline also extracts `cloudnative-pg` for the database superuser). If you cannot ask for the field names, leave `<FIXME: 1password field name>` placeholders and call them out.

## Step 3: Register in the namespace kustomization

Add `./<app>/ks.yaml` to `kubernetes/apps/<namespace>/kustomization.yaml` `resources`, in alphabetical position (`namespace.yaml` stays first; leave commented-out entries where they are).

**New namespace?** Copy an existing namespace folder (for example `default`) with its `namespace.yaml` (keep the literal `name: _`, the Pod Security labels and the `prune: disabled` annotation) and `kustomization.yaml` (keep the `alerts` and `kopiur/secret` components). The FluxInstance syncs `./kubernetes/apps`; confirm with `flate test` that it is picked up.

## Step 4: Network policy

Add `networkpolicy.yaml` for any app that is routed or reachable from other pods. Copy zipline's (an app with a database and OIDC) or seerr's, and read the network-policy bullet in `AGENTS.md`. Minimum for a routed app:

- ingress from the gateway pods (`envoy-external` or `envoy-internal`, namespace `network`) on the container port;
- the pods it calls through Services (`kube-dns`, `postgres17` in `database`, `dragonfly`, other apps), because the replies come back as "new" traffic to the pod, or `fromEntities: cluster` on `32768`-`60999` for an app that calls many Services;
- the specific in-cluster callers (Homepage widget, Home Assistant, Prometheus, ...);
- for an app that does OIDC against `auth.f9.casa`, the gateway pods on any port (their replies come from the listener port).

For a public app or one that holds credentials, also add `egress` (see the network-policy bullet in `AGENTS.md`): `kube-dns` on 53 with the `dns` proxy rule, each in-cluster target (`toEndpoints`) **and the same target under `ingress`**, off-cluster addresses with `toCIDR`, internet hosts with `toFQDNs` on 443. Copy zipline's (no internet) or seerr's (named hosts).

A `LoadBalancer`, hostNetwork or Multus-attached app needs thought: Cilium does not see the Multus interfaces. The server-side dry run (`kubectl apply --dry-run=server -f networkpolicy.yaml`) validates the manifest; the real test is after merge, with Hubble (`Policy denied DROPPED`).

## Step 5: Verify

```bash
kustomize build kubernetes/apps/<namespace>/<app>/app   # must render; ${APP} variables staying literal is expected
flate test all --path ./kubernetes/apps                  # when tools and network access permit
```

`lefthook` formats on commit. Show the user the created files and get confirmation before committing. Commit style: `feat(<app>): deploy`. After merge, check the app, the route, and Hubble for drops. If the app changes exposure or adds a dependency, the private technical docs and the risk register may need an update.

## Common mistakes

- **Copying a chart version or image tag from this skill or from memory**: read the current version from the repo (Step 2 command) and upstream.
- **Forgetting `reloader.stakater.com/auto`**: without it, secret or config changes do not restart pods.
- **`readOnlyRootFilesystem: true` without a tmpfs**: apps that write to `/tmp` crash; mount an `emptyDir`.
- **Putting an admin tool on `envoy-external`**: default to `envoy-internal`.
- **A public route with no login**: add the `ext-auth` component, or confirm the app does its own OIDC.
- **An egress rule with no matching ingress rule**: the connection opens and its reply is dropped, so it times out (Immich's SMTP relay, f9-homelab#2091).
- **A network policy that omits the reply paths**: the app then fails intermittently (DNS) or cannot reach its database, and Hubble shows `Policy denied DROPPED` from `kube-dns` or the database pods.
- **Guessing 1Password field names**: a wrong name renders an empty value silently.
- **Mounting NFS without `zeroscaler` and the `csi-driver-nfs` dependency**: the pod then hangs when the NAS is down.
- **Skipping the ordering conventions**: see `.agents/instructions/sorting.instructions.md`.
- **Using volsync**: this repository uses kopiur.
