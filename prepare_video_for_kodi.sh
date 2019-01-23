#!/bin/bash
shopt -s nocasematch

#/usr/bin/finishforkodi

# This script scans "indir" for vdr-recording-subdirs with already cut, but not for deletion marked movies and glues all ts-files
# there together to one file. This file is renamed in to "Title(year).ts" so that Movie scrapers can recognize the file
# properly and so collect additional info and fanart from the internet. At last the script moves all finished files to "outdir"
# for further processing e.g. by Handbrake or for simply viewing them. :-)
# The original recording is deleted nad a log-file is placed insind "indir".
#
# "indir" and "outdir" can be defined by editing the following two lines:  


indir="/video0/"
# --- Do not edit behind this line. ---

find ${indir} -path *.rec | while read recording; do
  outdir="/mnt/qnap_vdr/"
  name=""
  
  #Überspringe den Ordner Radio
  if [[ ${recording} =~ radio ]]
  then
    continue
  fi
  
  cd "${recording}"
  title="$(grep  ^T info | sed -e 's/^T //g' -e 's/[.:]//g' -e 's/|/\n/g')"
  subtitle="$(grep  ^S info | sed -e 's/^S //g' -e 's/[.:]//g' -e 's/|/\n/g')"
  year="$(grep  ^S info | sed -r -e 's/[^0-9]*//g' -e 's/[0-9]+/(&)/')"


  if [[ ${recording} =~ serien ]]
  then
    outdir="${outdir}Serien/${title}/"
    mkdir --parents "${outdir}"
  else
    outdir="${outdir}Filme/"
    name="${title}"
  fi

  #Testen, ob subtitle gefüllt ist
  if [[ -n "${subtitle}" ]]
  then
    name="${name} ${subtitle}"
  fi

  if [[ -z "${name}" ]]
  then
    name="${title}"
  fi

  #Testen, ob year gefüllt ist
  if [[ -n "${year}" ]]
  then
    name="${name}-${year}"
  fi

  name=${name}.ts
  #Sodnerzeichen entfernen/ersetzen
  name="$(sed s/[\'\"\`]//g <<<$name)"
  name="$(sed s/[\/]/~/g <<<$name)"

  outdir_name="${outdir}${name}"

  test -e "${outdir_name}" && rm -f "${outdir_name}"
     for tsfile in $(find -name "0000[0-9].ts" | sort); do
           my_path=$(pwd)
           echo "Concatenating ${tsfile} ${outdir_name}"
           cat "${tsfile}" >> "${outdir_name}"
     done
  cd ..
  test -e "${recording}" && test -s "${outdir_name}" && rm -rf "${recording}"
  find ${indir} -type d -empty -delete
  date -R|tr '\n' ' '>> ${indir}finishforkodi.log; echo "Movie '${name}' successfully renamed and concatenated." >> ${indir}finishforkodi.log
done
