#!/bin/bash
#Backupskript - Backup with rsync and ssh
#Version: 0.0.1-initial (2014-11-28)
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

###config
#SSH (key login required)
ssh_target="pax";
ssh_user="backups";
ssh_dir="/home/backups/md0/xray504/";

backup_dir="/home/tilman/Backup/xray504/";

script_path=$(dirname "$(readlink -e "$0")");
log_file=${script_path}"/backup_"${ssh_target}".log";
lock_file=${script_path}"/backup_"${ssh_target}".lock";

###script begins here
##functions
#log and send notification (sendxmpp)
notify_log() {
 now_msg=$(/bin/date +%Y%m%d-%H%M%S);
 `echo ${now_msg}": "${notify_log_msg} | sendxmpp -t -u xray504 -j b4r.eu -p lai3is6i timaba@timaba.de`;
 `echo ${now_msg}": "${notify_log_msg} >> ${log_file}`;
 unset notify_log_msg;
 unset now_msg;
}
#delete lock-file and end
lock_delete_end() {
 rm ${lock_file};
 exit;
}

##check for lock & log
if [ -e ${lock_file} ]; then
 now_msg=$(/bin/date +%Y%m%d-%H%M%S);
 `echo ${now_msg}": Backup läuft bereits. Breche ab." >> {log_file}`;
 unset now_msg;
 exit;
else 
 touch ${lock_file};
fi

if [ ! -f ${log_file} ];then
 touch ${log_file};
fi

##check for last local backup
#backup_last=`ls -d ${backup_dir}[[:digit:]]* | /usr/bin/sort -r | /usr/bin/head -1 `;
#if [ -d ${backup_dir} ]; then
# notify_log_msg="Letztes Backup [lokal]: "${backup_last};
# notify_log;
#else
# notify_log_msg="Kein lokales Backup gefunden";
# notify_log;
#fi

##check for last local backup
backup_dir_last=`ls -d ${backup_dir}[[:digit:]]* | /usr/bin/sort -r | /usr/bin/head -1 `;
if [ -d ${backup_dir_last} ]; then
 notify_log_msg="Letztes lokales Backup: "${backup_dir_last};
 notify_log;
else
 notify_log_msg="Kein lokales Backup gefunden";
 notify_log;
fi


##check for last remote backup
ssh_login="${ssh_user}@${ssh_target}";
if [ "${ssh_dir}" ]; then
 backup_target_last=`ssh ${ssh_login} ls -d ${ssh_dir}[[:digit:]]* | /usr/bin/sort -r | /usr/bin/head -1 `;
 notify_log_msg="Letztes Backup [${ssh_target}]: "${backup_target_last};
 notify_log;
fi

##rsync
start_backup="rsync --link-dest=${backup_target_last} -avze ssh ${backup_dir_last} ${ssh_login}:${ssh_dir} ";
${start_backup};

lock_delete_end;
