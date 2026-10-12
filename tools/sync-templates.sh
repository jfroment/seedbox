#!/bin/bash

##############################################################################
############################## TEMPLATES SYNC ################################
##############################################################################
#
# Configuration files you have to fill with your own values are shipped as
# templates (files with ".sample" in their name). The files really used by the
# seedbox are copies of them, ignored by git, that you can freely edit.
#
# This script creates the missing files and, when a template changes (after a
# "git pull" for example), carries the change over to your file:
#   - file never edited          => replaced by the new template
#   - file edited                => 3-way merge (your changes are kept)
#   - merge conflict             => file left untouched, a warning is shown
#   - .env, config.yaml & co     => never touched, a warning is shown
#
# Files of a service (services/<name>/*.sample.* => services/<name>/custom/) are
# only created when the service is enabled in config.yaml.
#
# Usage:
#   tools/sync-templates.sh                 Synchronize (also done by run-seedbox.sh)
#   tools/sync-templates.sh status          Show the state of every file
#   tools/sync-templates.sh diff [file]     Show template changes not applied yet + your own changes
#   tools/sync-templates.sh accept <file>   Mark template changes as handled (after a manual merge)

set -e
shopt -s nullglob

cd "$(dirname "$0")/.."

# Copy of each template as it was when last synchronized (the "base" of the 3-way merge)
BASE_DIR=".seedbox/base"
# Copy of your files as they were before the last automatic merge
BACKUP_DIR=".seedbox/backup"

# List all templates, one per line: "template|file|mode". Modes:
#   notify   => created if missing, never modified afterwards (only a warning when the template changes)
#   service  => created if missing and if the service is enabled, template changes are merged
list_templates() {
  local t f
  for t in .env.sample config.sample.yaml docker-compose.sample.yaml; do
    [[ -f $t ]] || continue
    echo "$t|${t/.sample/}|notify"
  done
  # Configuration files of services: your copy is in the custom directory of the service
  for t in services/*/*.sample.*; do
    f=$(basename $t)
    echo "$t|$(dirname $t)/custom/${f/.sample/}|service"
  done
}

# Check if the service owning a file ($1 = services/<name>/custom/<file>) is enabled in config.yaml
# (config.yaml in v2 format is supported too, as this script is used during the migration)
is_service_enabled() {
  local name=${1#services/}
  name=${name%%/*}
  # Traefik config is always generated
  [[ ${name} == "traefik" ]] && return 0
  if [[ -z ${ENABLED_SERVICES+x} ]]; then
    ENABLED_SERVICES=""
    if [[ -f config.yaml ]]; then
      ENABLED_SERVICES=$(yq '.services | (select(tag == "!!map") | to_entries | .[] | select(.value.enabled != false) | .key), (select(tag == "!!seq") | .[] | select(.enabled != false) | .name)' config.yaml | tr '\n' ' ')
    fi
  fi
  [[ " ${ENABLED_SERVICES} " == *" ${name} "* ]]
}

save_base() {
  #$1 => template
  #$2 => file
  mkdir -p "$(dirname "$BASE_DIR/$2")"
  cp "$1" "$BASE_DIR/$2"
}

# State of a file compared to its template
get_state() {
  #$1 => template
  #$2 => file
  local base="$BASE_DIR/$2"
  if [[ ! -f $2 ]]; then
    echo "missing"
  elif [[ -f $base ]] && ! cmp -s "$1" "$base" && ! cmp -s "$1" "$2"; then
    echo "outdated"
  elif cmp -s "$1" "$2"; then
    echo "identical"
  else
    echo "customized"
  fi
}

sync_one() {
  #$1 => template
  #$2 => file
  #$3 => mode
  local template=$1 file=$2 mode=$3 base="$BASE_DIR/$2"

  if [[ ! -f $file ]]; then
    if [[ $mode == "service" ]] && ! is_service_enabled "$file"; then
      return 0
    fi
    mkdir -p "$(dirname "$file")"
    cp "$template" "$file"
    save_base "$template" "$file"
    echo "[$0] Created $file from $template"
    return 0
  fi

  # File which existed before this script was used: consider it is based on the current template
  if [[ ! -f $base ]]; then
    save_base "$template" "$file"
    return 0
  fi

  # Template did not change since last synchronization
  cmp -s "$template" "$base" && return 0

  # Template changed but the file is already the same
  if cmp -s "$template" "$file"; then
    save_base "$template" "$file"
    return 0
  fi

  if [[ $mode == "notify" ]]; then
    echo "[$0] ⚠️  $template has changed. Check if you need to update your $file:"
    echo "[$0]       $0 diff $file      (then: $0 accept $file)"
    return 0
  fi

  # Template changed and the file was never edited
  if cmp -s "$file" "$base"; then
    cp "$template" "$file"
    save_base "$template" "$file"
    echo "[$0] Updated $file from $template"
    return 0
  fi

  # Template changed and the file was edited: 3-way merge
  local merged=$(mktemp)
  if which git >/dev/null && git merge-file -p -q "$file" "$base" "$template" > "$merged" 2>/dev/null; then
    mkdir -p "$(dirname "$BACKUP_DIR/$file")"
    cp "$file" "$BACKUP_DIR/$file"
    cat "$merged" > "$file"
    save_base "$template" "$file"
    echo "[$0] Merged changes of $template into $file (previous version saved in $BACKUP_DIR/$file)"
  else
    echo "[$0] ⚠️  $template has changed but it conflicts with your changes in $file. Merge it manually:"
    echo "[$0]       $0 diff $file      (then: $0 accept $file)"
  fi
  rm -f "$merged"
}

show_diff() {
  #$1 => template
  #$2 => file
  local base="$BASE_DIR/$2"
  if [[ $(get_state $1 $2) == "outdated" ]]; then
    echo "########## $2: changes of $1 not applied yet ##########"
    diff -u --label "$1 (previous)" --label "$1 (new)" "$base" "$1" || true
  fi
  if [[ -f $2 ]] && ! cmp -s "$1" "$2"; then
    echo "########## $2: your changes compared to $1 ##########"
    diff -u --label "$1" --label "$2" "$1" "$2" || true
  fi
}

command=${1:-sync}
target=$2
found=0

if [[ $command != "sync" && $command != "status" && $command != "diff" && $command != "accept" ]]; then
  echo "[$0] ❌ ERROR: unknown command \"$command\". Usage: $0 [sync|status|diff [file]|accept <file>]"
  exit 1
fi
if [[ $command == "accept" && -z $target ]]; then
  echo "[$0] ❌ ERROR: \"accept\" needs a file. Usage: $0 accept <file>"
  exit 1
fi

while IFS='|' read -r template file mode; do
  [[ -n $target && $target != "$file" ]] && continue
  found=1
  case $command in
    sync)
      sync_one "$template" "$file" "$mode"
      ;;
    status)
      state=$(get_state "$template" "$file")
      if [[ $state == "missing" && $mode == "service" ]] && ! is_service_enabled "$file"; then
        state="not used"
      fi
      printf "%-12s %s\n" "$state" "$file"
      ;;
    diff)
      show_diff "$template" "$file"
      ;;
    accept)
      save_base "$template" "$file"
      echo "[$0] Changes of $template are now considered as applied to $file"
      ;;
  esac
done < <(list_templates)

if [[ -n $target && $found == 0 ]]; then
  echo "[$0] ❌ ERROR: \"$target\" is not a file managed by a template. See: $0 status"
  exit 1
fi
