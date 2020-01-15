#!/bin/bash

source scripts/multiArchMatrix.sh
source scripts/logger.sh

showHelp() {
	echo "Usage: $0 -i <Image name> -t <Tag name> -a <Target architecture> -b <Baseimage branch> -v <version> -r <VCS reference> -g <GitHub auth token>"
}

cleanup() {
	rm -rf build_tmp/
}

while getopts :hi:t:a:b:v:r:g: opt; do
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
		a)
			ARCH=$OPTARG
			;;
		b)
			BASEIMAGE_BRANCH=$OPTARG
			;;
		v)
			VERSION=$OPTARG
			;;
		r)
			VCS_REF=$OPTARG
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

echo ""
logTitle "Build parameters"
logSubTitle "Docker image: $DOCKER_IMAGE"
logSubTitle "Docker tag: $DOCKER_TAG"
logSubTitle "Architecture: $ARCH"
logSubTitle "Baseimage branch: $BASEIMAGE_BRANCH"
logSubTitle "Image version: $VERSION"
logSubTitle "VCS reference: $VCS_REF"
echo ""

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')


logTitle "Setting up multiarch build environment"
cleanup
mkdir -p build_tmp/qemu

if [ -z GITHUB_TOKEN ] || [ "$GITHUB_TOKEN" == "NONE" ]; then
	QEMU_RELEASE=$(curl -sS --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 1 --retry-max-time 60 "https://api.github.com/repos/multiarch/qemu-user-static/releases/latest" |grep '"tag_name":' |sed -E 's/.*"([^"]+)".*/\1/')
else
	QEMU_RELEASE=$(curl -u EdoFede:$GITHUB_TOKEN -sS --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 1 --retry-max-time 60 "https://api.github.com/repos/multiarch/qemu-user-static/releases/latest" |grep '"tag_name":' |sed -E 's/.*"([^"]+)".*/\1/')	
fi

if [ -z QEMU_RELEASE ]; then
	QEMU_RELEASE="v4.2.0-2"
fi

for i in ${!ARCHS[@]}; do
	if [ "${ARCHS[i]}" == "$ARCH" ]; then
		QEMU_ARCH=${QEMU_ARCHS[i]}
		break
	fi
done

if [ "$QEMU_ARCH" != "NONE" ]; then
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


logTitle "Start building"
cmdBuilt="docker build"
cmdBuilt+=" --build-arg BUILD_DATE=$BUILD_DATE"
if [ ! -z $ARCH ]; then
	cmdBuilt+=" --build-arg ARCH=$ARCH"
fi
if [ ! -z $BASEIMAGE_BRANCH ]; then
	cmdBuilt+=" --build-arg BASEIMAGE_BRANCH=$BASEIMAGE_BRANCH"
fi
if [ ! -z $VERSION ]; then
	cmdBuilt+=" --build-arg VERSION=$VERSION"
fi
if [ ! -z $VCS_REF ]; then
	cmdBuilt+=" --build-arg VCS_REF=$VCS_REF"
fi
cmdBuilt+=" --tag $DOCKER_IMAGE:$DOCKER_TAG-$ARCH"
cmdBuilt+=" ."

eval $cmdBuilt
if [ $? != 0 ]; then
	logError "Build failed"
	cleanup
	exit 3
fi

logNormal "Build done"
cleanup
