#!/bin/bash

# Jibri will call us with $1 as the directory of the recording.
DIR=$1
echo "Recording processor for recording of directory $DIR"

## encoding quality (lower == better)
# 23 is about 1.5x aka 45 FPS average on my hardware (6 core 12 thread Xeon 2.6GHz)
#QENC=23
#scaling (captured video is 720p)
#this one scales to 360p (divides by 2 both dimensions, keeping aspect 16:9)
#VSCALE="-vf scale=iw/2:-1"
#this one scales to 960p
#VSCALE="-vf scale=960:-1"

# note destination is within the container - so you should mount (bind mount) something to it or handle appropriately
# this destination moves the file to 'recordings' directory
DEST="$(cd $DIR && cd .. && pwd)"

#echo "Processing from $DIR to $DEST"
# here we find the mp4 file and convert it using x265 at configured scale and quality, leaving audio and framerate as is
#find "$DIR" -name "*mp4" -print0 | xargs -i'{}' -0 ffmpeg -i '{}' -c:v libx265 -crf $QENC -c:a copy $VSCALE '{}'.scaled.mp4

echo "moving to destination directory $DEST"
find "$DIR" -name "*mp4" -print0 | xargs -i'{}' -0 mv '{}' $DEST/`date +%d.%m.%y_%H-%M`_meeting.mp4

echo "Removing original files"
find "$DIR" -name "*mp4" -print0 | xargs -i'{}' -0 rm -f '{}'

rm -r $DIR

exit 0
