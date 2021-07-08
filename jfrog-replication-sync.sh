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
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X GET "${ARTIFACTORY_PRIMARY_URL}/api/replications/$repository_name" > $tmp_file

	### Change url befor push to secondary
	sed -i 's/$ARTIFACTORY_SECONDARY_URL/$ARTIFACTORY_PRIMARY_URL/' $tmp_file

	### Push the replication configuration of the repository to Secondary server
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X PUT -H "Content-Type: application/json" "${ARTIFACTORY_SECONDARY_URL}/api/replications/$repository_name" -d @$tmp_file

	### Change url and enabled value befor push to Primary
	sed -i 's/$ARTIFACTORY_PRIMARY_URL/$ARTIFACTORY_SECONDARY_URL/' $tmp_file
	sed -i 's/"enabled" .*$/"enabled" : false,/' $tmp_file

	### Push the replication configuration of the repository to Primary server
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X PUT -H "Content-Type: application/json" "${ARTIFACTORY_PRIMARY_URL}/api/replications/$repository_name" -d @$tmp_file
}

get_repositories_list
for i in $repositories_list ; do
	sync_replication_configuration $i
done
