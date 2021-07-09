#!/bin/bash

ARTIFACTORY_APP_USER='XXXXX'
ARTIFACTORY_APP_KEY='XXXXX'
ARTIFACTORY_PRIMARY_URL='https://XXXX/artifactory'
ARTIFACTORY_SECONDARY_URL='https://XXXX/artifactory'

get_repositories_list() {
	repositories_list=`curl -s -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY}  -X GET "${ARTIFACTORY_PRIMARY_URL}/api/repositories?type=local" | jq -r .[].key`
	echo "### List of Repositories ###"
	echo $repositories_list | tr " " "\n"
}

sync_replication_configuration() {
	repository_name=$1
	tmp_file='/tmp/repository.json'
	### Pull the replication configuration of the repository from Primary server
	echo "### Pull the replication configuration of $repository_name from $ARTIFACTORY_PRIMARY_URL ###"
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X GET "${ARTIFACTORY_PRIMARY_URL}/api/replications/$repository_name" > $tmp_file

	res=$(cat $tmp_file | jq .errors[].status)
	if (( "$res" == "404" )) ; then
		echo "Replication configuration isn't found!"
	else
		### Change url befor push to secondary
		sed -i 's/$ARTIFACTORY_SECONDARY_URL/$ARTIFACTORY_PRIMARY_URL/' $tmp_file
	
		### Push the replication configuration of the repository to Secondary server
		echo "### Push the replication configuration of $repository_name to $ARTIFACTORY_SECONDARY_URL ###"
		curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X PUT -H "Content-Type: application/json" "${ARTIFACTORY_SECONDARY_URL}/api/replications/$repository_name" -d @$tmp_file
	
		### Change url and enabled value befor push to Primary
		sed -i 's/$ARTIFACTORY_PRIMARY_URL/$ARTIFACTORY_SECONDARY_URL/' $tmp_file
		sed -i 's/"enabled" .*$/"enabled" : false,/' $tmp_file
	
		### Push the replication configuration of the repository to Primary server
		echo "### Disable the replication of $repository_name to $ARTIFACTORY_PRIMARY_URL ###"
		curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X PUT -H "Content-Type: application/json" "${ARTIFACTORY_PRIMARY_URL}/api/replications/$repository_name" -d @$tmp_file
	fi
}

get_repositories_list
for i in $repositories_list ; do
	sync_replication_configuration $i
done
