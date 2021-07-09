#!/bin/bash

ARTIFACTORY_APP_USER='XXXXX'
ARTIFACTORY_APP_KEY='XXXXX'
ARTIFACTORY_PRIMARY_URL='https://XXXX/artifactory'
ARTIFACTORY_SECONDARY_URL='https://XXXX/artifactory'

get_repositories() {
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

	if grep -q errors "$tmp_file"; then
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

get_users() {
	## Get users list
	users_list=`curl -s -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY}  -X GET "${ARTIFACTORY_PRIMARY_URL}/api/security/users" | jq -r .[].name`
	echo "### List of users ###"
	echo $users_list | tr " " "\n"
}

sync_users() {
	user_name=$1
	tmp_file='/tmp/user.json'

	### Pull the user configuration
	echo "### Pull the user configuration for $user_name from $ARTIFACTORY_PRIMARY_URL ###"
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X GET "${ARTIFACTORY_PRIMARY_URL}/api/security/users/$user_name" > $tmp_file

	### Push the user configuration to Secondary server
	echo "### Push the user configuration of $user_name to $ARTIFACTORY_SECONDARY_URL ###"
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X PUT -H "Content-Type: application/json" "${ARTIFACTORY_SECONDARY_URL}/api/security/users/$user_name" -d @$tmp_file
}

get_groups() {
	## Get groups list
	groups_list=`curl -s -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY}  -X GET "${ARTIFACTORY_PRIMARY_URL}/api/security/groups" | jq -r .[].name`
	echo "### List of Groups ###"
	echo $groups_list | tr " " "\n"
}

sync_groups() {
	group_name=$1
	tmp_file='/tmp/group.json'

	### Pull the user configuration
	echo "### Pull the group configuration of $group_name from $ARTIFACTORY_PRIMARY_URL ###"
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X GET "${ARTIFACTORY_PRIMARY_URL}/api/security/groups/$group_name" > $tmp_file

	### Push the group_name configuration to Secondary server
	echo "### Push the group_name configuration of $group_name to $ARTIFACTORY_SECONDARY_URL ###"
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X PUT -H "Content-Type: application/json" "${ARTIFACTORY_SECONDARY_URL}/api/security/groups/$group_name" -d @$tmp_file
}

get_permissions() {
	## Get Permissions list
	permissions_list=`curl -s -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY}  -X GET "${ARTIFACTORY_PRIMARY_URL}/api/security/permissions" | jq -r .[].name`
	echo "### Permissions List ###"
	echo $permissions_list | tr " " "\n"
}

sync_permissions() {
	permission_name=$1
	tmp_file='/tmp/permission.json'

	### Pull the permissions configuration
	echo "### Pull the permissions configuration of $permission_name from $ARTIFACTORY_PRIMARY_URL ###"
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X GET "${ARTIFACTORY_PRIMARY_URL}/api/security/permissions/$permission_name" > $tmp_file

	### Push the permissions configuration to Secondary server
	echo "### Push the permissions configuration of $permission_name to $ARTIFACTORY_SECONDARY_URL ###"
	curl -u ${ARTIFACTORY_APP_USER}:${ARTIFACTORY_APP_KEY} -X PUT -H "Content-Type: application/json" "${ARTIFACTORY_SECONDARY_URL}/api/security/permissions/$permission_name" -d @$tmp_file
}

get_repositories
for i in $repositories_list ; do
	sync_replication_configuration $i
done

get_users
for i in $users_list ; do
	sync_users $i
done

get_groups
for i in $groups_list ; do
	sync_groups $i
done

get_permissions
for i in $permissions_list ; do
	sync_permissions $i
done
