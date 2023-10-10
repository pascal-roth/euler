#!/bin/bash

# remote server
SERVER=rothpa@euler
SERVER_DIR=/cluster/scratch/rothpa/viplanner/data

# parent directory
PARENT_DIR=$1

# list of directories
DIRS=${@:2}

# loop over the directories
for DIR in $DIRS
do
    # check if directory exists in the parent directory
    if [[ -d "$PARENT_DIR/$DIR" ]]; then
        # create a tar file without compression
        tar -cf $PARENT_DIR/$DIR.tar -C $PARENT_DIR $DIR
        
        # rsync to a server location
        rsync -avzP $PARENT_DIR/$DIR.tar $SERVER:$SERVER_DIR
        
        # delete the tar file
        rm $PARENT_DIR/$DIR.tar
    else
        echo "Directory $DIR does not exist in the parent directory $PARENT_DIR. Skipping..."
    fi
done
