#!/bin/bash

# Usage: ./clean-fs.sh DIRECTORY
# Where DIRECTORY is the path of the directory to clean

##### THIS IS STILL WIP

if [ -z "${1}" ] ;then
 echo "[$0] Missing DIRECTORY parameter. Exiting..."
 exit 1
fi

f="${1}"
result="$(file $f)"
if [[ $result == *"cannot open"* ]] || [[ $result != *"directory"* ]];then
        echo "[$0] Directory not found (non-existing or is a file): ($result) ";
        exit 1;
fi

echo "[$0] Directory found: $1"

echo "[$0] Listing files which ARE NOT video files..."
find $1 -maxdepth 10 -type f | grep -v -E "\.webm$|\.flv$|\.vob$|\.ogg$|\.ogv$|\.drc$|\.gifv$|\.mng$|\.avi$|\.mov$|\.qt$|\.wmv$|\.yuv$|\.rm$|\.rmvb$|/.asf$|\.amv$|\.mp4$|\.m4v$|\.mp*$|\.m?v$|\.svi$|\.3gp$|\.flv$|\.f4v$"

while true; do
    read -p "[$0] Do you want to REMOVE these files?" yn
    case $yn in
        [Yy]* ) find $1 -maxdepth 10 -type f | grep -v -E "\.webm$|\.flv$|\.vob$|\.ogg$|\.ogv$|\.drc$|\.gifv$|\.mng$|\.avi$|\.mov$|\.qt$|\.wmv$|\.yuv$|\.rm$|\.rmvb$|/.asf$|\.amv$|\.mp4$|\.m4v$|\.mp*$|\.m?v$|\.svi$|\.3gp$|\.flv$|\.f4v$" | xargs rm -f; break;;
        [Nn]* ) echo "[$0] Skipping this part. Continuing...";;
        * ) echo "[$0] Please answer yes or no.";;
    esac
done

echo "[$0] Listing subdirectories of $1 which have a size under 5 MB..."
find $1 -mindepth 1 -maxdepth 1 -type d -exec du -ks {} + | awk '$1 <= 5000' | cut -f 2-

while true; do
    read -p "[$0] Do you want to REMOVE these folders?" yn
    case $yn in
        [Yy]* ) find $1 -mindepth 1 -maxdepth 1 -type d -exec du -ks {} + | awk '$1 <= 5000' | cut -f 2- | xargs -d \\n rm -rf; break;;
        [Nn]* ) echo "[$0] Skipping this part. Continuing...";;
        * ) echo "[$0] Please answer yes or no.";;
    esac
done

echo "[$0] End of script."

exit 0