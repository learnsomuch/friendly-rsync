#!/bin/bash

RSA_KEY=$1;
SOURCE_SERVER=$2;
SOURCE_DIRECTORY=$3;
TARGET_DIRECTORY=$4;
EXCLUDE_DIRECTORY=$5;

DATE_AND_TIME=`date`
HOSTNAME=`hostname`
NOW=$(date +"%F")
MASTER_LOGFILE="/adm/log/summary-rsync-$NOW.log"
CURRENT_LOGFILE="/adm/log/detailed-rsync-$NOW.log"

helpinfo() {
cat<<EOF
Usage : $0 rsa_key source_server source_directory target_directory exclude_directories 
options details: 
	rsa_key 		- You have to specify the rsa_key to connect to the respective server without password authentication.
		  	  	  Example: id_rsa_auth
	source_server 		- You have to specify the server details to which you want to connect and do a rsync.
	source_directory 	- You have to specify the folder you want to syncronize.
	target_directory 	- You have to specify the location you want to store the syncronized data.    
	exclude_directories	- You have to specify the directories which you do not want to get sync. 
				  Structure: source_path/folder1,source_path/folder2
				  Example: if the source directory is /www/, then exculde www and give remaining path like homefolder/folder1. If you have multiple folders, then give a comma "," between the different folders without space.

Sample Execution:
$0 id_rsa_auth server_name_or_IP_address /www/ /www/ homepages/folder1,homepages/folder2,homepages/folder3,homepages/tmp 
EOF
exit 0
}

[ ${4} ] || helpinfo

echo ${DATE_AND_TIME} $'\n' > ${MASTER_LOGFILE}
eval $(ssh-agent);
if [ $? -ne 0 ]; then
	echo ${DATE_AND_TIME} "command eval ssh-agent failed" >> ${MASTER_LOGFILE};
else
	ssh-add /root/.ssh/${RSA_KEY}
	if [ $? -ne 0 ]; then
		echo ${DATE_AND_TIME} "Adding ssh-key failed" >> ${MASTER_LOGFILE};
	fi	
fi

echo ${DATE_AND_TIME} "SSH key added to start rsync dry-run" >> ${MASTER_LOGFILE};


EXCLUDE_DIRECTORY=${EXCLUDE_DIRECTORY}
LIST=$(echo ${EXCLUDE_DIRECTORY} | tr ',' ' ')
EXCLUDE=""
for PATTERN in $LIST; do EXCLUDE="--exclude=$PATTERN ${EXCLUDE}"; done
rsync -avzh ${SOURCE_SERVER}:${SOURCE_DIRECTORY} ${TARGET_DIRECTORY} ${EXCLUDE}  >> ${CURRENT_LOGFILE}
echo "rsync -avzh ${SOURCE_SERVER}:${SOURCE_DIRECTORY} ${TARGET_DIRECTORY} ${EXCLUDE}"
if [ $? -ne 0 ]; then
	echo "Failed to run sync. see the log ${CURRENT_LOGFILE} to debug" >> ${MASTER_LOGFILE};
else
	echo "rsync run results :" >> ${MASTER_LOGFILE};
	tail -3 ${CURRENT_LOGFILE} >> ${MASTER_LOGFILE};
	echo " "; >> ${MASTER_LOGFILE};
	echo "For detailed log, refer to current log at ${CURRENT_LOGFILE}" >> ${MASTER_LOGFILE};
fi

kill ${SSH_AGENT_PID}
if [ $? -ne 0 ]; then
	echo ${DATE_AND_TIME} "failed to kill ssh-agent with a pid ${SSH_AGENT_PID}" >> ${MASTER_LOGFILE};
else
	echo ${DATE_AND_TIME} "Killed ssh-agent successfully" >> ${MASTER_LOGFILE};
fi

