#!/bin/bash

#set -x

#test="-t 60"
#test="-t 1"
videodir=/video

d=$(basename $PWD)
d1=$(echo $d | cut -d '.' -f 1-2)
d2=$(echo $d | cut -d '.' -f 3)
if [ "${d2:0:1}" == "0" ]
then
    d2=${d2:1:1}
fi
d2=$(($d2+1))
if [ ${#d2} == 1 ]
then
    d2=0$d2
fi
d3=$(echo $d | cut -d '.' -f 4-)
dest=$d1.$d2.$d3

t=/tmp/info
t2=/tmp/info2
if [ -e 00001.ts ]
then
    ffmpeg -i 00001.ts 2> $t
    fmt=ts
    w="*.ts"
    info=info
fi
if [ -e 001.vdr ]
then
    ffmpeg -i 001.vdr 2> $t
    fmt=vdr
    w="0*.vdr"
    info=info.vdr
    dest=$(echo $dest | cut -d '.' -f 1-3)."1-0.rec"
fi

mkdir ../$dest
log="../$dest/logfile"
ls -lk > $log

#d2=$(dirname $PWD)
#title=$(basename $d2)

#info=$(ffmpeg -i 00001.ts | grep "Stream" | grep "Audio")
#cp $t $log
cat $t >> $log
#info=$(cat $t | grep "Stream" | grep "Audio")
grep "Stream" $t | grep "Audio" > $t2
#cat $t2

# Stream #0:1[0x25a](deu): Audio: mp2 ([3][0][0][0] / 0x0003), 48000 Hz, stereo, s16, 192 kb/s (clean effects)
# Stream #0:2[0x25b](2ch): Audio: mp2 ([3][0][0][0] / 0x0003), 48000 Hz, stereo, s16, 192 kb/s (clean effects)
# Stream #0:1[0x1c0]: Audio: mp2, 48000 Hz, stereo, s16, 192 kb/s

map="-map 0:0"
while read line
do
    echo $line
    stream1=$(echo $line | cut -d ' ' -f 2 | cut -d ':' -f 2 | cut -d '[' -f 1)
    stream=$(($stream1-1))
    codec=$(echo $line | cut -d ' ' -f 4)
    case "$codec" in
	"mp2" | "mp2,")
	    audio="$audio -c:a:$stream libfaac -b:a:$stream 128k"
	    ;;
	"ac3" | "ac3,")
	    audio="$audio -c:a:$stream copy"
	    ;;
    esac
    map="$map -map 0:$stream1"
done < $t2
audio="$audio -async 1"
grep "Stream" $t | grep "Subtitle" > $t2

# Stream #0:5[0xe7](deu): Subtitle: dvb_subtitle ([6][0][0][0] / 0x0006) (hearing impaired)

while read line
do
    echo $line
    stream1=$(echo $line | cut -d ' ' -f 2 | cut -d ':' -f 2 | cut -d '[' -f 1)
    #map="$map -map 0:$stream1"
    #sub="-c:s copy"
done < $t2
echo $map
echo $audio
echo $map >> $log
echo $audio >> $log
#exit

#gopt="-n"
#preset="-preset fast"
preset="-preset fast -tune film -profile:v main -crf 21 -maxrate 2000k -bufsize 1835k"
#audio="-c:a copy"
#audio="-c:a:0 libfaac -c:a:1 libfaac -b:a 128k -async 1"
#map="-map 0:0 -map 0:1 -map 0:2"

#flist=/tmp/flist
#flist=flist
#rm $flist
#files="-i \"concat:"
for r in $w
do
    #files="$files -i $r"
    #echo $r >> $flist
    #files="$files$r|"
    files="-i $r"
    o=$r
    if [ "$fmt" == "vdr" ]
    then
	o="00"$(basename $r .vdr).ts
    fi
    opt="$gopt $files $map -c:v libx264 $preset $audio $sub $test ../$dest/$o"
    echo ffmpeg $opt >> $log
    nice ffmpeg $opt
    done

#files=" -f concat -i $flist"
#files=${files:0:$((${#files}-1))}"\""

#exit

#ffmpeg -i 0000%d.ts
#ffmpeg -n -i 00001.ts -c:v libx264 -c:a copy $test ../$dest/00001.ts
#ffmpeg $gopt $files -c:v libx264 $preset $audio $test ../$dest/00001.ts

cp -p $info ../$dest/info

cd ../$dest

vdr=$VDRDIR/vdr

wd=$(pwd)
$vdr --genindex="$wd"

ffmpeg -i 00001.ts 2>> logfile

#/usr/bin/touch $videodir/.update
echo H264 > info.txt
