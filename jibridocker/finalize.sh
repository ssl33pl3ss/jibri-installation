
#!/bin/bash

# Jibri will call us with $1 as the directory of the recording.
DIR=$1
echo "Recording processor for recording of directory $DIR"

# create and get the target (destination) directory for recordings
DATE_NAME="$(date +%d.%m.%y_%H-%M-%S)"
TEMP_DEST="$(cd $DIR && cd .. && pwd)"
mkdir $TEMP_DEST/$DATE_NAME
DEST="$TEMP_DEST/$DATE_NAME"

# delete the oldest recording if the number of recordings is more than 150
RECORDINGSCOUNT=$(find /config/recordings/* -maxdepth 1 -type d | wc -l)
OLDESTDIR="$(find /config/recordings/* -type d -printf '%T+ %p\n' | sort | head -1 | sed 's/^[^/]*\//\//' | cat)"
if (( RECORDINGSCOUNT > 150 )); then
    rm -r $OLDESTDIR
fi

# move files to target directory
echo "Moving to destination directory $DEST"
find "$DIR" -name "*mp4" -print0 | xargs -i'{}' -0 mv '{}' $DEST/"$DATE_NAME"_meeting.mp4
find "$DIR" -name "*json" -print0 | xargs -i'{}' -0 mv '{}' $DEST/"$DATE_NAME"_metadata.json

rm -r $DIR

# split recording if its size is greater than 1GB
cd $DEST
FILESIZE=$(stat -c%s "$DATE_NAME"_meeting.mp4)
if (( FILESIZE > 1000000000 )); then
    /bin/bash /config/split-recordings.sh "$DATE_NAME"_meeting.mp4 1000000000 "-c copy"
fi

exit 0
