#!/bin/bash

rsync -av --delete /video0/ /mnt/qnap_vdr >> /var/log/rsync_video0.txt
