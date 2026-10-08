#!/bin/sh
# Builds the two MkDocs sites (housemate guides + admin-only technical docs) from this
# repository's docs/ folder and keeps them up to date. Each build goes into its own
# directory and a symlink is swapped atomically, so nginx never serves a half-built site.
set -eu

REPO_URL="https://github.com/fma965/f9-homelab.git"
SRC=/work/repo
SITE=/site

export HOME=/tmp
export PYTHONDONTWRITEBYTECODE=1
export NO_MKDOCS_2_WARNING=true

build() {
    rev=$(git -C "$SRC" rev-parse --short HEAD)
    for site in guides technical; do
        dest="$SITE/$site-$rev"
        if [ ! -d "$dest" ]; then
            mkdocs build --quiet --config-file "$SRC/docs/mkdocs.$site.yml" --site-dir "$dest"
        fi
        ln -sfn "$site-$rev" "$SITE/$site.tmp"
        mv -T "$SITE/$site.tmp" "$SITE/$site"
    done
    # Drop builds from older revisions
    for dir in "$SITE"/guides-* "$SITE"/technical-*; do
        case "$dir" in *-"$rev") ;; *) rm -rf "$dir" ;; esac
    done
    echo "Built docs at revision $rev"
}

refresh() {
    git -C "$SRC" fetch --quiet --depth 1 origin main
    git -C "$SRC" reset --quiet --hard FETCH_HEAD
    build
}

case "${1:-}" in
init)
    git clone --quiet --depth 1 --filter=blob:none --sparse --branch main "$REPO_URL" "$SRC"
    git -C "$SRC" sparse-checkout set docs
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
