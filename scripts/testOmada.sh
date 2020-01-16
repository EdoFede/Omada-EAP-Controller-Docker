#!/bin/bash

source scripts/multiArchMatrix.sh
source scripts/logger.sh

CONTAINER="Omada-EAP-Controller-test"
IMAGE="edofede/omada-eap-controller"

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
logSubTitle "Waiting for service to start"
for i in {1..30}; do
	echo -e ".\c"
	sleep 1
done
echo ""


logSubTitle "Checking Omada startup"
log=$(docker logs $CONTAINER 2>&1 |grep 'Omada Controller started')
if [ "$log" != "Omada Controller started" ]; then
	logError "Error: Omada controller is not starting"
	logError "Logfile:"
	logDetail "$(docker logs $CONTAINER 2>&1)"
	logError "Aborting..."
	cleanup
	exit 1;
fi
logNormal "[OK] Test passed"


logSubTitle "Checking Omada web server"
log=$(docker exec -ti $CONTAINER curl -v http://127.0.1.1:8088 |grep '302 Found')
if [ "$log" != "< HTTP/1.1 302 Found" ]; then
	logError "Error: web server is not responding properly"
	logError "Logfile:"
	logDetail "$(docker logs $CONTAINER 2>&1)"
	logError "Aborting..."
	cleanup
	exit 1;
fi
logNormal "[OK] Test passed"

cleanup
logNormal "Done"
