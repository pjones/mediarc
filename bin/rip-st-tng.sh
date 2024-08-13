#!/usr/bin/env bash

################################################################################
set -eu
set -o pipefail

################################################################################
output_dir="/var/lib/media/tvshows/Star Trek: The Next Generation (1987)"
input_files=()
dry_run=0
season=
episode=

################################################################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [dir|file]

  -h      This message
  -d      Dry run
  -s NUM  Set season number to NUM
  -e NUM  Set starting episode number to NUM

EOF
}

################################################################################
# Option arguments are in $OPTARG
while getopts "hds:e:" o; do
  case "${o}" in
  d)
    dry_run=1
    ;;

  s)
    season=$(printf "%d" "$OPTARG")
    ;;

  e)
    episode=$(printf "%d" "$OPTARG")
    ;;

  h)
    usage
    exit
    ;;

  *)
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

################################################################################
function read_season_num() {
  find "$output_dir" -type d -name 'Season*' -exec basename '{}' ';' |
    sed -E -e 's/^Season *//' -e 's/^0+//' |
    sort --numeric-sort |
    tail -1
}

################################################################################
function read_episode_num() {
  find "$output_dir/Season $(format_num "$season")" \
    -type f -name "$(basename "$output_dir")*" -exec basename '{}' ';' |
    sed -E -e 's/.*s[0-9]+e([0-9]+).*/\1/' -e 's/^0+//' |
    sort --numeric-sort |
    tail -1
}

################################################################################
function format_num() {
  local num=$1

  if [ -z "$num" ]; then
    echo "01"
  else
    printf "%02d" "$num"
  fi
}

################################################################################
function add_file_if_exists() {
  local dir=$1
  local file=$2

  if [ -e "$dir/$file" ]; then
    input_files+=("$dir/$file")
  fi
}

################################################################################
function encode_file() {
  local file=$1
  local output

  output="$output_dir/Season $(format_num "$season")"
  output="$output/$(basename "$output_dir")"
  output="$output - s$(format_num "$season")e$(format_num "$episode").m4v"

  local cmd=(
    "HandBrakeCLI"
    "--preset" "General/Very Fast 1080p30"
    "--input" "$file"
    "--output" "$output"
    "--audio" "3,2"
    "--aencoder" "av_aac,copy:dts"
    "--mixdown" "stereo,none"
  )

  echo "${cmd[@]}"

  if [ "$dry_run" -ne 1 ]; then
    "${cmd[@]}"
  fi
}

################################################################################
# Try to guess season and episode numbers:
if [ -z "$season" ]; then
  season=$(read_season_num)
fi

if [ -z "$episode" ]; then
  episode=$(read_episode_num)

  if [ -z "$episode" ]; then
    episode=1
  else
    episode=$((episode + 1))
  fi
fi

################################################################################
# Try to guess input files:
if [ $# -eq 0 ]; then
  # Try using current directory in next step:
  set -- "$(pwd)"
fi

if [ $# -eq 1 ] && [ -d "$1" ]; then
  while IFS= read -r -d '' file; do
    input_files+=("$file")
  done < <(find "$1" -type f -name '*.mkv' -print0 |
    sort --reverse --zero-terminated)
elif [ $# -gt 0 ]; then
  for file in "$@"; do
    if [ ! -e "$file" ]; then
      echo >&2 "ERROR: file doesn't exist: $file"
      exit 1
    fi

    input_files+=("$file")
  done
fi

if [ "${#input_files[@]}" -eq 0 ]; then
  echo >&2 "ERROR: no files to encode"
  exit 1
fi

################################################################################
# Okay, we have files and can do some encoding:
for file in "${input_files[@]}"; do
  encode_file "$file"
  episode=$((episode + 1))
done
