#!/bin/bash

source scripts/multiArchMatrix.sh
source scripts/logger.sh

CONTAINER="BaseImage-test"
IMAGE="edofede/baseimage"

function cleanup () {
	logSubTitle "Stopping test container"
	docker stop $CONTAINER
	logSubTitle "Removing test container"
	docker rm $CONTAINER
}

echo ""
logTitle "Testing image: $IMAGE:$1"

logSubTitle "Creating test container"
docker create --name $CONTAINER --publish-all $IMAGE:$1


logSubTitle "Starting test container"
docker start $CONTAINER
sleep 4



logSubTitle "Checking syslog-ng startup"
log=$(docker logs $CONTAINER 2>&1 |grep 'syslog-ng starting up' |sed 's/.*\(syslog-ng starting up\).*/\1/')
if [ "$log" != "syslog-ng starting up" ]; then
	logError "Error: syslog-ng not started"
	logError "Aborting..."
	cleanup
	exit 1;
fi
logNormal "[OK] Test passed"


logSubTitle "Checking STDOUT logging"
docker exec -ti $CONTAINER logger "STDOUT test message"
log=$(docker logs --tail 1 $CONTAINER |sed 's/.*\(STDOUT test message\).*/\1/')
if [ "$log" != "STDOUT test message" ]; then
	logError "Error: test message to STDOUT failed"
	logError "Aborting..."
	cleanup
	exit 1;
fi
logNormal "[OK] Test passed"


logSubTitle "Checking STDERR logging"
docker exec -ti $CONTAINER logger -s "STDERR test message"
log=$(docker logs --tail 1 $CONTAINER |sed 's/.*\(STDERR test message\).*/\1/')
if [ "$log" != "STDERR test message" ]; then
	logError "Error: test message to STDERR failed"
	logError "Aborting..."
	cleanup
	exit 1;
fi
logNormal "[OK] Test passed"

cleanup
logNormal "Done"
