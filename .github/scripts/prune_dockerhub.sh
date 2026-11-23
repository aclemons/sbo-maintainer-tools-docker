#!/usr/bin/env bash
#
# Prune old per-build tags from a Docker Hub repository.
#
# The format for per-build tags is: <version>-<flavour>-<date>-<run>-sha<hash>
#
# This script will delete tags that match the above format and are older than a
# given number of months.
#
# For each old tag:
#   1. delete the tag (Docker Hub api, not in official docs)
#   2. delete its manifests by digest (registry api), unless a remaining tag
#      still references the digest (multi-arch children included)
#
# Use --execute to actually delete, otherwise the script runs in dry mode.
#
# Needs bash 4+, GNU date, curl and jq, plus the credentials in
# DOCKERHUB_USERNAME and DOCKERHUB_TOKEN.

set -e
set -o pipefail

DOCKERHUB=https://hub.docker.com
REGISTRY=https://registry-1.docker.io
AUTH=https://auth.docker.io/token

# Groups: 1=version 2=flavour 3=date 4=run 5=sha
IMMUTABLE_RE='^([0-9][^-]*)-(15\.0|current)-([0-9]{8})-([0-9]{6})-sha([0-9a-f]{12})$'

MANIFEST_ACCEPT='application/vnd.oci.image.index.v1+json'
MANIFEST_ACCEPT+=', application/vnd.docker.distribution.manifest.list.v2+json'
MANIFEST_ACCEPT+=', application/vnd.oci.image.manifest.v1+json'
MANIFEST_ACCEPT+=', application/vnd.docker.distribution.manifest.v2+json'

usage() {
  cat >&2 <<'EOF'
Usage: prune_dockerhub.sh --repo namespace/name --max-age-months N [--execute]

  --repo             Docker Hub repository, e.g. aclemons/sbo-maintainer-tools
  --max-age-months   Delete per-build tags older than this many months (at least 1)
  --execute          Delete for real (default is a dry run)
EOF
  exit 2
}

abort() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

REPO=""
MAX_AGE_MONTHS=""
EXECUTE=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo)           REPO=${2:-}; shift 2 ;;
    --max-age-months) MAX_AGE_MONTHS=${2:-}; shift 2 ;;
    --execute)        EXECUTE=1; shift ;;
    *) usage ;;
  esac
done

[[ $REPO == */* ]] || usage

if ! [[ $MAX_AGE_MONTHS =~ ^[0-9]+$ ]] || (( MAX_AGE_MONTHS < 1 )); then
  abort "--max-age-months must be an integer of at least 1"
fi

: "${DOCKERHUB_USERNAME:?DOCKERHUB_USERNAME is not set}"
: "${DOCKERHUB_TOKEN:?DOCKERHUB_TOKEN is not set}"

NS=${REPO%%/*}
NAME=${REPO#*/}

CUTOFF=$(date -u -d "$MAX_AGE_MONTHS months ago" +%Y%m%d)

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

TAGS=()
OLD_TAGS=()
DELETED_TAGS=()
STALE_DIGESTS=()
FAILURES=0
MANIFESTS_DELETED=0

# Sets the global variable STATUS to the HTTP status code of the request.
# The response body is written to $TMP/body and the headers to $TMP/headers.
request() {
  local method=$1 url=$2

  shift 2

  STATUS=$(curl -sS -X "$method" -D "$TMP/headers" -o "$TMP/body" -w '%{http_code}' "$@" "$url" </dev/null) || STATUS=000
}

dockerhub_login() {
  HUB_TOKEN=$(jq -cn '{username: env.DOCKERHUB_USERNAME, password: env.DOCKERHUB_TOKEN}' \
    | curl -sS -f -X POST "$DOCKERHUB/v2/users/login/" -H 'Content-Type: application/json' \
        --data-binary @- \
    | jq -er '.token') || abort "Docker Hub login failed"
}

registry_token() {
  REGISTRY_TOKEN=$(curl -sS -f -K <(printf 'user = "%s:%s"\n' "$DOCKERHUB_USERNAME" "$DOCKERHUB_TOKEN") \
    "$AUTH?service=registry.docker.io&scope=repository:$REPO:pull,delete" \
    | jq -er '.token') || abort "Registry token request failed"
}

github_auth() {
  printf 'header = "Authorization: JWT %s"\n' "$HUB_TOKEN"
}

registry_auth() {
  printf 'header = "Authorization: Bearer %s"\n' "$REGISTRY_TOKEN"
}

list_tags() {
  local url="$DOCKERHUB/v2/namespaces/$NS/repositories/$NAME/tags?page_size=100"

  : > "$TMP/tags"

  while [[ -n $url ]]; do
    request GET "$url" -K <(github_auth)

    [[ $STATUS == 200 ]] || abort "Listing tags failed: HTTP $STATUS"

    jq -r '.results[].name' "$TMP/body" >> "$TMP/tags"

    url=$(jq -r '.next // empty' "$TMP/body")
  done

  mapfile -t TAGS < "$TMP/tags"
}

plan_deletions() {
  local tag

  for tag in "${TAGS[@]}"; do
    if [[ $tag =~ $IMMUTABLE_RE && ${BASH_REMATCH[3]} < $CUTOFF ]]; then
      OLD_TAGS+=("$tag")
    fi
  done
}

collect_digests() {
  local tag digest

  : > "$TMP/reach"

  for tag in "${TAGS[@]}"; do
    request GET "$REGISTRY/v2/$REPO/manifests/$tag" -K <(registry_auth) -H "Accept: $MANIFEST_ACCEPT"

    [[ $STATUS == 200 ]] || abort "Reading manifest for $REPO:$tag failed: HTTP $STATUS"

    digest=$(tr -d '\r' < "$TMP/headers" | awk 'tolower($1) == "docker-content-digest:" {print $2}')

    [[ -n $digest ]] || abort "No Docker-Content-Digest for $REPO:$tag"

    printf '%s %s\n' "$tag" "$digest" >> "$TMP/reach"

    jq -r --arg tag "$tag" '.manifests[]?.digest | "\($tag) \(.)"' "$TMP/body" >> "$TMP/reach"
  done
}

delete_tags() {
  local tag

  for tag in "${OLD_TAGS[@]}"; do
    request DELETE "$DOCKERHUB/v2/repositories/$NS/$NAME/tags/$tag/" -K <(github_auth)

    if [[ $STATUS == 200 || $STATUS == 204 ]]; then
      printf '  deleted tag %s\n' "$tag"

      DELETED_TAGS+=("$tag")
    else
      printf '  FAILED to delete tag %s: HTTP %s\n' "$tag" "$STATUS"

      FAILURES=$((FAILURES + 1))
    fi
  done
}

find_stale_digests() {
  local tag digest
  local -A deleted dropped kept

  for tag in "${DELETED_TAGS[@]}"; do
    deleted[$tag]=1
  done

  while read -r tag digest; do
    if [[ -n ${deleted[$tag]} ]]; then
      dropped[$digest]=1
    else
      kept[$digest]=1
    fi
  done < "$TMP/reach"

  for digest in "${!dropped[@]}"; do
    [[ -n ${kept[$digest]} ]] || STALE_DIGESTS+=("$digest")
  done
}

delete_manifests() {
  local pending=("$@") refused d
  local -A reason

  while (( ${#pending[@]} > 0 )); do
    refused=()

    for d in "${pending[@]}"; do
      request DELETE "$REGISTRY/v2/$REPO/manifests/$d" -K <(registry_auth)

      if [[ $STATUS == 202 || $STATUS == 404 ]]; then
        printf '  deleted manifest %s (HTTP %s)\n' "$d" "$STATUS"

        MANIFESTS_DELETED=$((MANIFESTS_DELETED + 1))
      else
        reason[$d]="HTTP $STATUS $(head -c 300 "$TMP/body" | tr '\n' ' ')"

        refused+=("$d")
      fi
    done

    (( ${#refused[@]} < ${#pending[@]} )) || break

    pending=("${refused[@]}")
  done

  for d in "${pending[@]}"; do
    printf '  FAILED to delete manifest %s: %s\n' "$d" "${reason[$d]}"

    FAILURES=$((FAILURES + 1))
  done
}

dockerhub_login
list_tags
plan_deletions

printf '%s tags found, %s built before %s to delete\n' "${#TAGS[@]}" "${#OLD_TAGS[@]}" "$CUTOFF"

for tag in "${OLD_TAGS[@]}"; do
  printf '  delete %s\n' "$tag"
done

if (( ${#OLD_TAGS[@]} == 0 )); then
  exit 0
fi

if (( EXECUTE == 0 )); then
  printf 'Dry run: nothing deleted. Re-run with --execute to delete.\n'
  exit 0
fi

registry_token
collect_digests
delete_tags
find_stale_digests
delete_manifests "${STALE_DIGESTS[@]}"

printf 'Done: %s tags deleted, %s manifests deleted, %s failures\n' \
  "${#DELETED_TAGS[@]}" "$MANIFESTS_DELETED" "$FAILURES"

if (( FAILURES > 0 )); then
  exit 1
fi
