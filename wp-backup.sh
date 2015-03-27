#!/usr/bin/env bash
# WP-Backup - Creates a Backup of your WordPress database and files and stores them to your Mega.co.nz cloud storage.
# Author: Gavin Eke | Twitter: @gavineke | GitHub: https://github.com/GavinEke | Website: https://gavineke.com

# Dependencies: mailutils, megatools
# Change the variables below to suit your environment
WP_FOLDER="/var/www/html"
BACKUP_FOLDER="."
DATE=$(date +%Y-%m-%d)
LOG="${BACKUP_FOLDER}/wp-backup.log"
EMAIL="youremail@yourhost.com"
MEGA_BACKUP_DIR="/Root/WebsiteBackup"

echo "WordPress Backup Log ${DATE}" > ${LOG}
echo "" >> ${LOG}

if [ -z ${WP_FOLDER} ] || [ -z ${BACKUP_FOLDER} ]; then
	echo "Cannot find ${WP_Folder} and/or ${BACKUP_FOLDER}" >> ${LOG}
	exit 1
fi
 
# check if it looks like wordpress installation
WP_CONFIG="${WP_FOLDER}/wp-config.php"
 
if ! test -f ${WP_CONFIG}; then 
	echo "ERROR: Cannot detect WordPress installation here... Exiting" >> ${LOG}
	exit 1
fi
 
# get the database connection
DB_NAME=$(grep -E "^define\('DB_NAME'" ${WP_CONFIG} | cut -d"'" -f4)
DB_USER=$(grep -E "^define\('DB_USER'" ${WP_CONFIG} | cut -d"'" -f4)
DB_PASSWORD=$(grep -E "^define\('DB_PASSWORD'" ${WP_CONFIG} | cut -d"'" -f4)
DB_HOST=$(grep -E "^define\('DB_HOST'" ${WP_CONFIG} | cut -d"'" -f4)
 
# doing the backup
mysqldump ${DB_NAME} -u${DB_USER} -p${DB_PASSWORD} -h${DB_HOST} | gzip > ${BACKUP_FOLDER}/sitedb-${DATE}.gz;
 
if [ $? -ne 0 ]; then
	echo "ERROR: Couldn't dump your database. Check your permissions" >> ${LOG}
	exit 1
fi
 
tar -zcf ${BACKUP_FOLDER}/sitefiles-${DATE}.tar.gz  ${WP_FOLDER}/  >/dev/null 2>&1
 
if [ $? -ne 0 ]; then
	echo "ERROR: Couldn't backup your WordPress directory..." >> ${LOG}
	exit 1
fi

# upload db to Mega
megaput --no-progress --path ${MEGA_BACKUP_DIR}/sitedb-${DATE}.gz ${BACKUP_FOLDER}/sitedb-${DATE}.gz >/dev/null 2>&1

if [ $? -ne 0 ]; then
	echo "ERROR: Couldn't upload website database to Mega" >> ${LOG}
	exit 1
fi

# upload site files to Mega
megaput --no-progress --path ${MEGA_BACKUP_DIR}/sitefiles-${DATE}.tar.gz ${BACKUP_FOLDER}/sitefiles-${DATE}.tar.gz >/dev/null 2>&1

if [ $? -ne 0 ]; then
	echo "ERROR: Couldn't upload website files to Mega" >> ${LOG}
	exit 1
fi

echo "Website Backup Completed Successfully" >> ${LOG}
echo "" >> ${LOG}
echo "$(megadf --human)" >> ${LOG}
echo "" >> ${LOG}
echo "$(megals ${MEGA_BACKUP_DIR})" >> ${LOG}

# email log
cat ${LOG} | mail -s "Website Backup Successful" ${EMAIL}
