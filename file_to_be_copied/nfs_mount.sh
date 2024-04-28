#!/bin/bash



NFS_IP="x.x.x.x"
NFS_PATH="folder"



if df | grep -q /mnt/NFS
then
    echo "NFS already mounted"
else
    sudo mount ${NFS_IP}:${NFS_PATH} /mnt/NFS
fi
