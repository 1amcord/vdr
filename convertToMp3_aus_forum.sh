# only do that for files in /radio/
if [ $# -gt 0 ]; then
  [ -n "`ffprobe $1/00001.ts 2>&1 | grep Stream.*Video`" ] && exit 0
  cd "$1"
    fi

    title="`grep ^T info | sed -e 's/^T //' -e 's/://g' -e 's/?//g'`"
    title=`echo $title | sed -e 's/"//g'`
    title=`echo $title | sed -e 's/?//g'`
    title=`echo $title | sed -e 's/\//-/g'`

    echo "Title: ${title}"

    station="`grep ^C info | awk '{ print substr($0, index($0,$3)) }'`"

    echo "Title: ${title}"

    datum=`echo $PWD | awk -F/ '{ print $NF }' | sed -e 's/\.[0-9]*-[0-9]*\.rec//' -e 's/-//g' -e 's/\.//g' -e 's/^20//'`
    shortdatum=`echo $datum | cut -c1-6`
    mydatum="`echo $datum | sed -e 's/\(..\)\(..\)\(..\)\(..\)\(..\)/\3.\2.\1 \4:\5/'`"
    year=`basename $PWD | awk -F- '{ print $1 }'`
    description="`grep ^D info | sed -e 's/^D //' | awk -F'|' '{ print $1 }'`"
    subject="`grep ^S info | sed -e 's~/~-~g' -e 's/^S //' -e 's/://'`"
    [ -z "$subject" ] && subject="$title"
    archive_title="${title}"

    datei=`echo $TARGETDIR/${station}/${archive_title}/${title}_${datum}_${subject} | sed -e 's/ /_/g' -e 's/_$//' -e 's/?//' -e 's/"//g' -e 's/\?//g' -e 's/__/_/g'`


    echo "Datei: ${datei}"

    # prefer ac3
    stream2use=`ffprobe $PWD/00001.ts 2>&1 | grep Stream.*Audio.*\ ac3 | head -1 | awk '{ print $2 }' | sed -e 's/\[.*//' -e 's/#//'`
    [ -z "$stream2use" ] && stream2use=`ffprobe $PWD/00001.ts 2>&1 | grep Stream.*Audio | head -1 | awk '{ print $2 }' | sed -e 's/\[.*//' -e 's/#//'`

#    # remove target first if it exists
#    [ -f $datei.mp3 ] && rm -f $datei.mp3
#
#    # bail out in case of broken recordings (encrypted)
#    [ `ls -1 0*.ts | wc -l` -eq 0 ] && exit 0
#
#    # prepare target directory
#    [ ! -d "`dirname $datei`" ] && mkdir -p "`dirname $datei`"
#
#    # convert the file
#    cat 0*.ts | ffmpeg -i - -map $stream2use -acodec libmp3lame -f mp3 \
#              -loglevel quiet \
#                -metadata title="$subject" \
#                  -metadata artist="$title $mydatum" \
#                    -metadata author="$station" \
#                      -metadata year="$year" \
#                        -metadata album="$archive_title" \
#                          -ab 256k \
#                            -ar 44100  \
#                              $datei.mp3
#
#    # add info file as comment
#    TMP1=`tempfile`
#    cat info  >> $TMP1
#    echo      >> $TMP1
#    echo $PWD >> $TMP1
#    eyeD3 --no-color -Y $year -n 1 -N 1 --set-encoding utf8 --comment=:INFO:""`cat $TMP1`"" "$datei.mp3"
#    rm -f $TMP1
#
#    # add cover picture
#    [ -f "$LOGODIR/$station.png" ] && eyeD3 --no-color --add-image="$LOGODIR/$station.png":FRONT_COVER "$datei.mp3" || logger -i -p kern.info -t `basename $0` "Kein Logo fuer >$station<"
