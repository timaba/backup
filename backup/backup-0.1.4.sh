#!/bin/bash
#Backupskript - Backup with rsync and ssh
#Version: 0.1.4 (2014-04-22)
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
## SSH-Verbindung (Achtung: Zugang nur mit Schlüssel!)
SSH_SERVER="tilmanne-box.fritz.box";
SSH_USER="tilman";

## Ordner müssen mit / enden.
SOURCE="/home/tilman/";
EXCLUDE=${SOURCE}".skripte/backup/excludes";
LOG_FILE=${SOURCE}".skripte/backup/backup.log";
DEST_PATH="/home/tilman/md0/Backup/X220/";

###Skript beginnt, unterhalb nichts ändern
BACKUPICON="/home/tilman/.icons/icon_backup.png"; 
NOW_START=$(/bin/date +%Y%m%d-%H%M%S);

##Funktionen
notify_log() {
 NOW_MSG=$(/bin/date +%Y%m%d-%H%M%S);
 `notify-send -i ${BACKUPICON} "${NOW_MSG}: ${NOTIFY_LOG_MSG}"`;
 `echo ${NOW_MSG}": "${NOTIFY_LOG_MSG} >> ${LOG_FILE}`;
 unset NOTIFY_LOG_MESSAGE;
 unset NOW_MSG;
}

##Serverereichbarkeit
if arp | grep ${SSH_SERVER}; then 
  NOTIFY_LOG_MSG=${SSH_SERVER}" gefunden";
  notify_log; ##Wirklich nötig - wenn alles läuft?
 else
  NOTIFY_LOG_MSG=${SSH_SERVER}" NICHT gefunden";
  notify_log; 
  exit; #Ende
fi

DEST_SSH=${SSH_USER}"@"${SSH_SERVER};

# Prüfen ob bereits Backups existieren.
if [ "${DEST_PATH}" ]; then
 LASTBACKUP=`ssh ${DEST_SSH} ls -d ${DEST_PATH}[[:digit:]]* | /usr/bin/sort -r | /usr/bin/head -1 `;
 NOTIFY_LOG_MSG="Letztes Backup: "${LASTBACKUP};
 notify_log;
fi

# Neuen Ordner anlegen.
DESTINATION=${DEST_PATH}${NOW_START};
ssh ${DEST_SSH} mkdir -p ${DESTINATION};

# Hardlinks definieren.
if [ "${LASTBACKUP}" ]; then
 INC="--link-dest=${LASTBACKUP}"
fi

# Rsync aufrufen.
EXCLUDIRS="--exclude-from="${EXCLUDE};
END="rsync -aze ssh --progress ${EXCLUDIRS} ${INC} ${SOURCE} ${DEST_SSH}:${DESTINATION}";
${END};

NOTIFY_LOG_MSG="Backup beendet.";
notify_log;

exit;