#!/bin/sh
# Builds the private technical MkDocs site from fma965/f9-homelab-docs (read-only deploy key)
# and keeps it up to date. Each build goes into its own directory and a symlink is swapped
# atomically, so nginx never serves a half-built site.
set -eu

REPO_URL="git@github.com:fma965/f9-homelab-docs.git"
SRC=/work/repo
SITE=/site

export HOME=/tmp
export PYTHONDONTWRITEBYTECODE=1
export NO_MKDOCS_2_WARNING=true

# ssh refuses a group-readable key, and the Secret mount is group-readable via fsGroup, so use a copy
install -m 600 /secrets/id_ed25519 /tmp/id_ed25519
echo >> /tmp/id_ed25519
export GIT_SSH_COMMAND="ssh -i /tmp/id_ed25519 -o IdentitiesOnly=yes -o UserKnownHostsFile=/secrets/known_hosts -o StrictHostKeyChecking=yes"

build() {
    rev=$(git -C "$SRC" rev-parse --short HEAD)
    dest="$SITE/site-$rev"
    if [ ! -d "$dest" ]; then
        mkdocs build --quiet --config-file "$SRC/mkdocs.yml" --site-dir "$dest"
    fi
    ln -sfn "site-$rev" "$SITE/current.tmp"
    mv -T "$SITE/current.tmp" "$SITE/current"
    # Drop builds from older revisions
    for dir in "$SITE"/site-*; do
        case "$dir" in *-"$rev") ;; *) rm -rf "$dir" ;; esac
    done
    echo "Built docs at revision $rev"
}

refresh() {
    git -C "$SRC" fetch --quiet --depth 1 origin main
    git -C "$SRC" reset --quiet --hard FETCH_HEAD
    build
}

case "$*" in
init)
    git clone --quiet --depth 1 --branch main "$REPO_URL" "$SRC"
    build
    ;;
watch)
    while sleep 300; do
        refresh || echo "Refresh failed, keeping the current site"
    done
    ;;
*)
    echo "usage: $0 init|watch" >&2
    exit 1
    ;;
esac
