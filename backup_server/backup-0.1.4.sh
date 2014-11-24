#!/bin/bash
#Backupskript - Local backup with rsync for small server
#Version: 0.0.1 (2014-11-22)
#
#Copyright (C) 2014  Tilman Bartsch <tba@timaba.de>
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, 
#or any later version.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

### Konfigurationen
## Ordner müssen mit / enden.
#Verzeichnis des Skriptes finden
PFAD=$(dirname "$(readlink -e "$0")");
HOST=`hostname`;

#Ursprungsverzeichnis des Backup
SOURCE=(` cat "${PFAD}/dirlist.conf" `);

#Pfad zu Datei mit auszuschließenden Dateien/Ordnern
EXCLUDE=${PFAD}"/excludes";

#Pfad zu Logdatei
LOG_FILE="/var/log/backup/backup_"${HOST}".log";

#Pfad zu Lock-Datei
LOCK_FILE=${PFAD}"/backup_"${HOST}".lock";

#Zielpfad des Backup
DEST_PATH="/home/tilman/md0/Backup/pax/";

###Skript beginnt, unterhalb dieser Zeile nichts ändern
NOW_START=$(/bin/date +%Y%m%d-%H%M%S);

##Test Log/Lock-Datei
if [ -e ${LOCK_FILE} ]; then
 NOW_MSG=$(/bin/date +%Y%m%d-%H%M%S);
 `echo ${NOW_MSG}": Backup läuft bereits. Breche ab." >> ${LOG_FILE}`;
 unset NOW_MSG;
 exit;
else 
 touch ${LOCK_FILE};
fi

if [ ! -f ${LOG_FILE} ];then
 touch ${LOG_FILE};
fi

##Funktionen
#Log und Notify-Nachricht
notify_log() {
 NOW_MSG=$(/bin/date +%Y%m%d-%H%M%S);
 `echo ${NOW_MSG}": "${NOTIFY_LOG_MSG} | sendxmpp -t -u pax -j b4r.eu -p lai3is6i timaba@timaba.de`;
 `echo ${NOW_MSG}": "${NOTIFY_LOG_MSG} >> ${LOG_FILE}`;
 unset NOTIFY_LOG_MESSAGE;
 unset NOW_MSG;
}

#Lock-Datei löschen und Skript beenden
lock_delete_end() {
 rm ${LOCK_FILE};
 exit;
}

# Prüfen ob bereits Backups existieren.
if [ "${DEST_PATH}" ]; then
 LASTBACKUP=`ls -d ${DEST_PATH}[[:digit:]]* | /usr/bin/sort -r | /usr/bin/head -1 `;
 NOTIFY_LOG_MSG="Letztes Backup: "${LASTBACKUP};
 notify_log;
fi

# Neuen Ordner anlegen.
DESTINATION=${DEST_PATH}${NOW_START};
`mkdir -p ${DESTINATION}`;

# Hardlinks definieren, wenn vorheriges Backup gefunden.
if [ "${LASTBACKUP}" ]; then
 INC="--link-dest=${LASTBACKUP}"
fi

# Rsync aufrufen.
EXCLUDIRS="--exclude-from="${EXCLUDE};
for SOURCE in "${SOURCE[@]}"
do
 END="rsync -az ${EXLUDIRS} ${INC} ${SOURCE[@]} ${DESTINATION}";
${END};
done

NOTIFY_LOG_MSG="Backup beendet.";
notify_log;
lock_delete_end;

