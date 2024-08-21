#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
album=NO

################################################################################
usage() {
  cat <<EOF
Usage: beet-tag [options] tags

  -a  Tag albums

Example:

  beet-tag -a rating=1.0
EOF
}

################################################################################
while getopts "ah" o; do
  case "${o}" in
  a)
    album=YES
    ;;

  h)
    usage
    exit
    ;;

  *)
    echo "Bad arguments"
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

################################################################################
do_search() {
  local options=()
  local key="title"

  if [ "$album" = "YES" ]; then
    options+=("-a")
    key="album"
  fi

  # shellcheck disable=SC2016
  beet ls "${options[@]}" "${key}:$1" -f '$id - $albumartist - $album' |
    head -1
}

################################################################################
do_tag() {
  local options=()
  local the_id=$1
  shift

  if [ "$album" = "YES" ]; then
    options+=("-a")
  fi

  beet modify -y "${options[@]}" "id:$the_id" "$@"
}

################################################################################
while :; do
  read -rp "Search: " answer

  match=$(do_search "$answer")
  echo "$match"
  read -rp "Tag: (y|n) " answer

  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    the_id=$(echo "$match" | cut -d' ' -f1)
    do_tag "$the_id" "$@"
  fi
done
