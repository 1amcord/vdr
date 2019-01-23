#!/bin/bash

LOGFILE=/var/log/convertToMp3.log
log(){
	message="$(date +"%Y-%m-%d_%H-%M-%S") - $@"
	echo $message
	echo $message >>$LOGFILE
}

log ""
log ""
log "---------------------Tach! Verzeichnis: ${1}--------------------"

#Basisverzeichnis, gequotet mittels printf
BASEDIR=$(printf %q ${1})
log "Basedir: ${BASEDIR}"



#Überprüfe die erste *.ts-Datei, ob typ video vorhanden. Wenn ja, steige aus, da anscheinend kein Radio.
ERSTE_DATEI=$(ls -t ${BASEDIR}/*.ts | head -n 1)
log "Teste, ob Datei: <${ERSTE_DATEI}> ein Video ist"

VIDEO=`ffprobe -loglevel error -show_entries stream=codec_type ${ERSTE_DATEI}`

log "ffprobe-String: <${VIDEO}>"

shopt -s nocasematch
if [[ ${VIDEO} =~ .*video.* ]]
then
	log "Video. Datei wird nicht konvertiert"
	exit 0
fi

log "Kein Video, konvertiere."


#Überprüfen, ob die info-Datei existiert. Wenn nicht, aussteigen

INFO_DATEI=$1/info
log "INFO-Datei: <${INFO_DATEI}>"

if [[ -f $INFO_DATEI ]]
then
	TITEL="`grep ^T ${INFO_DATEI} | sed -e 's/^T //' -e 's/://g' -e 's/?//g'`" 

#	TITEL=$(basename $(dirname ${BASEDIR}))
	
	station="`grep ^C ${BASEDIR}/info | awk '{ print substr($0, index($0,$3)) }'`"
	
	year=`basename ${BASEDIR} | awk -F- '{ print $1 }'`

	KURZTEXT=$(sed -n 's/^S \(.*\)$/\1/p' <${INFO_DATEI})
	BESCHREIBUNG=$(sed -n 's/^D \(.*\)$/\1/p' <${INFO_DATEI})
else
	log "Info-Datei nicht gefunden, Abbruch"
	exit 1
fi

GENRE="Radio"
JAHR=$(date +'%Y')


#Das Datum wird aus dem Verzeichnispfad der Aufnahme ermittelt. Uhrzeit und .rec werden entfernt
DATUM=${BASEDIR##*/}
DATUM=${DATUM:0:10}

#Wenn das Datum weniger als 10 Zeichen hat, nehme aktuelles Datum.
#if ((${#DATUM} < 10))
#then
#	DATUM=$(date +'%Y-%m-%d')
#fi

MP2NAMEWOSUFFIX="${DATUM}_${TITEL}"
MP2NAMEWOSUFFIX=$(echo ${MP2NAMEWOSUFFIX} | sed 's/[\(\)\/]/_/g')
MP2FILE=${MP2NAMEWOSUFFIX}.mp2
AUDIODIR="/tmp"
MEDIADIR="/mnt/qnap_multimedia/audiorecorder"

if [ -e "${MEDIADIR}/${MP2FILE}" ]
then
	COUNTER=2
	MP2FILE="${MP2NAMEWOSUFFIX}(${COUNTER}).mp2"

	while [ -e "${MEDIADIR}/${MP2FILE}" ]
	do
		${COUNTER} = ${COUNTER} + 1
		MP2FILE="${MP2NAMEWOSUFFIX}(${COUNTER}).mp2"
	done
fi

# prefer ac3
stream2use=`ffprobe ${ERSTE_DATEI} 2>&1 | grep Stream.*Audio.*\ ac3 | head -1 | awk '{ print $2 }' | sed -e 's/\[.*//' -e 's/#//'` 
[ -z "$stream2use" ] && stream2use=`ffprobe ${ERSTE_DATEI} 2>&1 | grep Stream.*Audio | head -1 | awk '{ print $2 }' | sed -e 's/\[.*//' -e 's/#//'`

log "stream2use: ${stream2use}"

# convert the file
cat `ls -t ${BASEDIR}/*.ts` | ffmpeg -i - -map $stream2use \
	-acodec copy \
       	-metadata title="${TITEL}" \
       	-metadata author="$station" \
       	-metadata year="$year" \
       	-metadata comment="${BESCHREIBUNG}" \
       	-metadata album="Audiorecorder" \
       	"${AUDIODIR}/${MP2FILE}"

##Schreibe id3-Tags

#Tags für mp3
#/usr/bin/lltag \
#--mp3 \
#--yes \
#--ALBUM "Audiorecorder" \
#--TITLE "${TITEL}" \
#--COMMENT "${BESCHREIBUNG}" \
#--DATE "${year}" \
#"${AUDIODIR}/${MP2FILE}"

#Schreibrechte für User easyvdr
chmod 664 "${AUDIODIR}/${MP2FILE}"

mv "${AUDIODIR}/${MP2FILE}" ${MEDIADIR}

#RSS File aktualisieren
#log "RSS-Datei aktualisieren"


#/var/lib/vdr/scripte/makeatomfile.pl --dir ${MEDIADIR} --domain 192.168.178.25/audiorecorder --title "Cords Audiorecorder" --desc "Radioaufnahmen" > /var/www/podcast.xml

log "Erfolgreich beendet"

