#!/bin/bash
#Backupskript - Local backup with rsync for small servers
#Version: 0.2.2 (2016-06-22)
#
#Copyright (C) 2016  Tilman Bartsch <tba+github@timaba.de>
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
SOURCE=(` cat "${PFAD}/backup_dirs.conf" `);

#Pfad zu Datei mit auszuschließenden Dateien/Ordnern
EXCLUDE=${PFAD}"/backup_excl.conf";

#Pfad zu Logdatei
LOG_FILE=${PFAD}"/backup.log";

#Pfad zu Lock-Datei
LOCK_FILE=${PFAD}"/backup.lock";

#Zielpfad des Backup
DEST_PATH="/path/to/backup";

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
 `echo ${NOW_MSG}": "${NOTIFY_LOG_MSG} | sendxmpp -t -u xray504 -j b4r.eu -p lai3is6i timaba@timaba.de`;
 `echo ${NOW_MSG}": "${NOTIFY_LOG_MSG} >> ${LOG_FILE}`;
 unset NOTIFY_LOG_MESSAGE;
 unset NOW_MSG;
}

#Lock-Datei löschen und Skript beenden
lock_delete_end() {
 rm ${LOCK_FILE};
 exit;
}

##Weitere Vorbereitungen
# Prüfen ob bereits Backups existieren.
if [ "${DEST_PATH}" ]; then
 LASTBACKUP=`ls -d ${DEST_PATH}[[:digit:]]* | /usr/bin/sort -r | /usr/bin/head -1 `;
 NOTIFY_LOG_MSG="Letztes Backup: "${LASTBACKUP};
 notify_log;
fi

##Backup der MySQL-Datenbank
# Ordner anlegen
#`mkdir -p ${DESTINATION}"/MYSQL"`;
#`savelog -n -l -q -c $BACKUP_NUM "$BACKUP_DIR/mysql.sql"
#`mysqldump -u root -pXXXXXXX --all-databases ${DESTINATION}"/MYSQL/backup.sql"`;
#NOTIFY_LOG_MSG="MySQL-Backup: "${DESTINATION}"/MYSQL/backup.sql"; 
#notify_log;

## Backup der Daten
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
