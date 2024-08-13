#!/bin/sh -e

################################################################################
# Things you can change:
MINUTES=30
OUTFILE=out
VIDEO_DEVICE=/dev/video0
AUDIO_DEVICE="alsa_input.pci-0000_00_1d.0-usb-0_1.5.analog-stereo"

################################################################################
usage() {
  cat <<EOF
Usage: vcr.sh [options]

  -m MIN   Record for MIN minutes
  -n FILE  Set output file to FILE
EOF
}

################################################################################
while getopts "hm:n:" o; do
  case "${o}" in
    h) usage
       exit
       ;;

    m) MINUTES=$OPTARG
       ;;

    n) OUTFILE=$OPTARG
       ;;

    *) echo "bad arguments"
       usage
       exit 1
       ;;
  esac
done

shift $((OPTIND-1))

################################################################################
SECONDS=`expr $MINUTES \* 60 + 10`

################################################################################
ffmpeg \
  -thread_queue_size 1024 \
  -i "$VIDEO_DEVICE" \
  -thread_queue_size 1024 \
  -f pulse -i "$AUDIO_DEVICE" \
  -codec:v libx264 \
  -profile:v baseline -level 3.0 \
  -preset slower \
  -b:v 1000k -vf scale=352:480 -vf yadif \
  -pix_fmt yuv420p \
  -codec:a aac \
  -b:a 196k \
  -threads 0 \
  -loglevel error \
  -stats \
  -t $SECONDS \
  -strict -2 \
  "$OUTFILE".mp4
