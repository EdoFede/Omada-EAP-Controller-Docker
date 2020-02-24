#!/bin/bash

source scripts/multiArchMatrix.sh
source scripts/logger.sh

showHelp() {
	echo "Usage: $0 -i <Image name> -t <Tag name> -p <Platform (`printf '%s ' "${PLATFORMS[@]}"`)> -d <0/1 debug enabled>"
}

cleanup() {
	rm -rf build_tmp
}

getQemu() {
	echo ""
	logTitle "Setting up qemu for multiarch"

	cleanup
	
	if [ -z GITHUB_TOKEN ] || [ "$GITHUB_TOKEN" == "NONE" ]; then
		QEMU_RELEASE=$(curl -sS --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 1 --retry-max-time 60 "https://api.github.com/repos/multiarch/qemu-user-static/releases/latest" |grep '"tag_name":' |sed -E 's/.*"([^"]+)".*/\1/')
	else
		QEMU_RELEASE=$(curl -u EdoFede:$GITHUB_TOKEN -sS --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 1 --retry-max-time 60 "https://api.github.com/repos/multiarch/qemu-user-static/releases/latest" |grep '"tag_name":' |sed -E 's/.*"([^"]+)".*/\1/')	
	fi
	
	if [ -z QEMU_RELEASE ]; then
		QEMU_RELEASE="v4.2.0-2"
	fi
	
	for i in ${!PLATFORMS[@]}; do
		if [ "${PLATFORMS[i]}" == "$PLATFORM" ]; then
			QEMU_ARCH=${QEMU_ARCHS[i]}
			break
		fi
	done
	
	if [ "$QEMU_ARCH" != "NONE" ]; then
		mkdir -p build_tmp/qemu

		curl -sS -L \
			--connect-timeout 5 \
			--max-time 10 \
			--retry 5 \
			--retry-delay 0 \
			--retry-max-time 60 \
			https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_RELEASE/qemu-$QEMU_ARCH-static.tar.gz \
			-o build_tmp/qemu-$QEMU_ARCH-static.tar.gz && \
		tar zxvf \
			build_tmp/qemu-*-static.tar.gz \
			-C build_tmp/qemu/
	
		if [ $? != 0 ]; then
			logError "Download or extraction failed"
			cleanup
			exit 2
		fi
	fi
	logNormal "Done"
}

while getopts :hi:t:p:d:g: opt; do
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
		d)
			DEBUG=$OPTARG
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

getQemu
qemuFile=$(ls build_tmp/qemu/ 2> /dev/null)

echo ""
logTitle "Run parameters"
logSubTitle "Docker image: $DOCKER_IMAGE"
logSubTitle "Docker tag: $DOCKER_TAG"
logSubTitle "Platform: $PLATFORM"
logSubTitle "Qemu file: $qemuFile"
logSubTitle "Debug: $DEBUG"
echo ""

logSubTitle "Pulling image from registry"
docker pull --platform=linux/$PLATFORM $DOCKER_IMAGE:$DOCKER_TAG
logNormal "Done"

logSubTitle "Starting image"
cmdRun="docker run --rm"
if [ "$DEBUG" == 1 ]; then
	cmdRun+=" -ti"
fi
cmdRun+=" --platform=linux/$PLATFORM"
if [ -n "$qemuFile" ]; then
	cmdRun+=" --volume $(pwd)/build_tmp/qemu/$qemuFile:/usr/bin/$qemuFile"
fi
cmdRun+=" --publish-all"
cmdRun+=" $DOCKER_IMAGE:$DOCKER_TAG"
if [ "$DEBUG" == 1 ]; then
	cmdRun+=" /bin/bash"
fi
logNormal "Run command:"
logDetail "$cmdRun"
echo ""
eval $cmdRun

docker image rm $(docker image ls -q $DOCKER_IMAGE)
cleanup
