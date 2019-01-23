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
#if [ -e $'/media/easyvdr01/video0/Radio/Rock\'n\'_Roll-Radio/2015.01.04-21:00-So/2015-01-04.20.58.24-0.rec/info' ]
then
	TITEL=$(sed -n 's/^T \(.*\)$/\1/p' <${INFO_DATEI})
	KURZTEXT=$(sed -n 's/^S \(.*\)$/\1/p' <${INFO_DATEI})
	BESCHREIBUNG=$(sed -n 's/^D \(.*\)$/\1/p' <${INFO_DATEI})
else
	log "Info-Datei nicht gefunden, Abbruch"
	exit 1
fi

GENRE="Radio"
JAHR=$(date +'%Y')

#Wenn mehrere ts-Dateien vorhanden sind, Dateien zusammenfügen
ANZAHL_DATEIEN=`ls -tr ${BASEDIR}/*.ts | wc -l`

if [ $ANZAHL_DATEIEN -gt 1 ];
then
	for ts in ${BASEDIR}/*.ts;
	do
		log "Verarbeite: ${ts}"
		cat ${ts} >> "${BASEDIR}/stream.ts"
		rm -f ${ts};
	done
fi

#Jetzt ist nur eine ts-Datei vorhanden, ermittle den Namen
TSDATEI=`ls ${BASEDIR}/*.ts`

#Das Datum wird aus dem Verzeichnispfad der Aufnahme ermittelt. Uhrzeit und .rec werden entfernt
DATUM=${BASEDIR##*/}
DATUM=${DATUM:0:10}

#Wenn das Datum weniger als 10 Zeichen hat, nehme aktuelles Datum.
if ((${#DATUM} < 10))
then
	DATUM=$(date +'%Y-%m-%d')
fi

MP3NAMEWOSUFFIX="${DATUM}_${KURZTEXT}_${TITEL}"
MP3FILE=$(echo ${MP3NAMEWOSUFFIX} | sed 's/[\(\)\/]/_/g').mp3

echo "Nach der Ersetzung: ${MP3FILE}"

