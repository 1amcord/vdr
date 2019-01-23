#!/bin/bash

cp convertToMp3.sh /var/lib/vdr/scripte
chown vdr:vdr /var/lib/vdr/scripte/convertToMp3.sh

cp ./prepare_video_for_kodi.sh /var/lib/vdr/scripte/
chown vdr:vdr /var/lib/vdr/scripte/prepare_video_for_kodi.sh

cp makeatomfile.pl /var/lib/vdr/scripte
chown vdr:vdr /var/lib/vdr/scripte/makeatomfile.pl

cp makeatomfile_alle_aufnahmen.pl /var/lib/vdr/scripte
chown vdr:vdr /var/lib/vdr/scripte/makeatomfile_alle_aufnahmen.pl

