# This docs site

## How it works

```text
docs/ in Git ──(merge to main)──> pod "help" fetches main every 5 min
                                   builds two MkDocs sites into an emptyDir
                                   nginx serves them
```

| URL                               | Source                                          | Audience                     |
| --------------------------------- | ----------------------------------------------- | ---------------------------- |
| `https://help.f9.casa/`           | `docs/guides/` + `docs/mkdocs.guides.yml`       | Everyone in the `home` group |
| `https://help.f9.casa/technical/` | `docs/technical/` + `docs/mkdocs.technical.yml` | Admins only (Authelia rule)  |

The two sites are built separately so that the housemate search index never contains the technical pages.

## The pod (`kubernetes/apps/default/help`)

- `build` init container (squidfunk/mkdocs-material): sparse-clones `docs/` from `main` and runs the first build.
- `refresh` sidecar: every 5 minutes fetches `main` and rebuilds if the revision changed. The new build is swapped in with an atomic symlink. If a build fails, the previous site stays up and the failure is logged.
- `app` container (nginx-unprivileged): serves `/site/guides` at `/` and `/site/technical` at `/technical/`.
- The scripts and nginx config are in `kubernetes/apps/default/help/app/resources/`.

No image build or registry is involved. Updating the docs is just a PR to `docs/`.

## Editing

```sh
# Preview locally (needs Docker)
docker run --rm -it -p 8000:8000 -v "$PWD/docs:/docs" squidfunk/mkdocs-material \
  serve -f mkdocs.guides.yml -a 0.0.0.0:8000
# swap in mkdocs.technical.yml for the technical site
```

Add a page by creating the markdown file, then adding it to `nav:` in the matching config. Run a strict build before merging to catch broken links:

```sh
docker run --rm -v "$PWD/docs:/docs" squidfunk/mkdocs-material build --strict -f mkdocs.guides.yml -d /tmp/out
```

## Troubleshooting

```sh
kubectl -n default logs deploy/help -c refresh     # build output
kubectl -n default logs deploy/help -c app
kubectl -n default rollout restart deploy/help     # force a fresh clone and build
```
