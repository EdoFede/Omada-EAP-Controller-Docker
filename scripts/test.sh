#!/bin/bash

source scripts/multiArchMatrix.sh
source scripts/logger.sh

showHelp() {
	echo "Usage: $0 -i <Image name> -t <Tag name> -p <Test only platform (`printf '%s ' "${PLATFORMS[@]}"`)>"
}

while getopts :hi:t:p:g: opt; do
	case ${opt} in
		h)
			showHelp
			exit 0
			;;
		i)
			DOCKER_IMAGE=$OPTARG
			;;
		t)
			DOCKER_TAG=$OPTARG
			;;
		p)
			PLATFORM=$OPTARG
			;;
		g)
			GITHUB_TOKEN=$OPTARG
			;;
		\?)
			echo "Invalid option: $OPTARG" 1>&2
			showHelp
			exit 1
			;;
		:)
			echo "Invalid option: $OPTARG requires an argument" 1>&2
			showHelp
			exit 1
			;;
		*)
			showHelp
			exit 0
			;;
	esac
done
shift "$((OPTIND-1))"


for i in ${!PLATFORMS[@]}; do
	if [ -n "$PLATFORM" ] && [ "${PLATFORMS[i]}" != "$PLATFORM" ]; then
		continue
	fi

	echo ""
	logTitle "Testing image: $DOCKER_IMAGE:$DOCKER_TAG (${PLATFORMS[i]})"
	
	logSubTitle "Running test container"
	scripts/run.sh -i $DOCKER_IMAGE -t $DOCKER_TAG -p ${PLATFORMS[i]} &
	sleep 30
	echo ""

	containerId=$(docker container ls --filter ancestor=$DOCKER_IMAGE:$DOCKER_TAG -q)
	
	logSubTitle "Getting published TCP port on host"
	webPort=$(docker port $containerId 8088/tcp |cut -d ':' -f2)
	if [ -z $webPort ]; then
		logError "Error: unable to find published port"
		logDetail "Docker port output: $(docker port $containerId)"
		logError "Aborting..."
		docker stop $containerId
		exit 1;
	fi
	logNormal "[OK] Port 8088 mapped to: $webPort"
	
	
	if [ "${TEST_ENABLED[i]}" == "0" ]; then
		logNormal "Skipping tests for this architecture"
	else

		startOk=0
		for i in {1..30}; do
			echo -e ".\c"
			log=$(docker logs $containerId 2>&1 |grep 'Omada Controller started')
			if [ "$log" == "Omada Controller started" ]; then
				startOk=1;
				break
			fi
			sleep 1
		done
		echo ""

		logSubTitle "Checking Omada startup"
		if [ $startOk == 0 ]; then
			logError "Error: Omada controller is not starting"
			logError "Logfile:"
			logDetail "$(docker logs $containerId 2>&1)"
			logError "Aborting..."
			docker stop $containerId
			exit 1;
		fi
		logNormal "[OK] Test passed"
		
		
		logSubTitle "Checking Omada web server"
		# log=$(curl -If -s --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 1 --retry-max-time 30 http://localhost:$webPort 2>&1 |sed -n 1p)
		# log=$(echo $log |sed 's/\Found.*/Found/')
		# if [ "$log" != "HTTP/1.1 302 Found" ]; then
		
		log=$(curl -I -m 10 -o /dev/null -s -w %{http_code} http://localhost:$webPort/status)
		if [ "$log" != "200" ]; then
			logError "Error: web server is not responding properly"
			logError "Check return:"
			echo $log |cat -v
			logError "Logfile:"
			logDetail "$(docker logs $containerId 2>&1)"
			logError "HTTP response:"
			logDetail "$(curl -v http://localhost:$webPort)"
			logError "Aborting..."
			docker stop $containerId
			exit 1;
		fi
		logNormal "[OK] Test passed"
	fi
	
	docker stop $containerId
	sleep 3
	logNormal "Done"
done
