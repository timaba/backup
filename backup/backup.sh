#!/bin/bash
#Backupskript - Backup with rsync and ssh
#Version: 0.1.5 (2014-11-22)
#
#Copyright (C) 2014  Tilman Bartsch <tba+github@timaba.de>
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
ssh_server="pax.local";
ssh_user="tilman";

## Ordner müssen mit / enden.
#Verzeichnis des Skriptes finden
pfad=$(dirname "$(readlink -e "$0")");

#Ursprungsverzeichnis des Backup
source=${HOME};

#Pfad zu Datei mit auszuschließenden Dateien/Ordnern
exclude=${pfad}"/excludes";

#Pfad zu Logdatei
log_file=${pfad}"/backup.log";

#Pfad zu Lock-Datei
lock_file=${pfad}"/backup_running.lock";

#Zielpfad des Backup
dest_path="/home/tilman/md0/Backup/X220/";

###Skript beginnt, unterhalb dieser Zeile nichts ändern
icon=${HOME}"/.icons/icon_backup.png"; 
now_start=$(/bin/date +%Y%m%d-%H%M%S);

##Test Lock-Datei
if [ -e ${lock_file} ]; then
 now_msg_a=$(/bin/date +%Y%m%d-%H%M%S);
 `notify-send -i ${icon} "Backup" "${now_msg_a}: Laufendes Backup gefunden. Breche ab."`;
 unset now_msg_a;
 exit;
else 
 touch ${lock_file};
fi

##Funktionen
#Log und Notify-Nachricht
notify_log() {
 now_msg=$(/bin/date +%Y%m%d-%H%M%S);
 `notify-send -i ${icon} "Backup" "${now_msg}: ${notify_log_msg}"`;
 `echo ${now_msg}": "${notify_log_msg} >> ${log_file}`;
 unset notify_log_msg;
 unset now_msg;
}

#Lock-Datei löschen und Skript beenden
lock_delete_end() {
 rm ${lock_file};
 exit;
}

##Serverereichbarkeit
if avahi-resolve-host-name -n ${ssh_server}; then 
  notify_log_msg=${ssh_server}" gefunden";
  notify_log; ##Wirklich nötig - wenn alles läuft?
 else
  notify_log_msg=${ssh_server}" NICHT gefunden";
  notify_log;
  lock_delete_end;
 #Ende
fi

dest_ssh=${ssh_user}"@"${ssh_server};

# Prüfen ob bereits Backups existieren.
if [ "${dest_path}" ]; then
 lastbackup=`ssh ${dest_ssh} ls -d ${dest_path}[[:digit:]]* | /usr/bin/sort -r | /usr/bin/head -1 `;
 notify_log_msg="Letztes Backup: "${lastbackup};
 notify_log;
fi

# Neuen Ordner anlegen.
destination=${dest_path}${now_start};
ssh ${dest_ssh} mkdir -p ${destination};

# Hardlinks definieren, wenn vorheriges Backup gefunden.
if [ "${lastbackup}" ]; then
 inc="--link-dest=${lastbackup}"
fi

# Rsync aufrufen.
excludirs="--exclude-from="${exclude};
end="rsync -aze ssh ${excludirs} ${inc} ${source} ${dest_ssh}:${destination}";
${end};

notify_log_msg="Backup beendet.";
notify_log;
lock_delete_end;
