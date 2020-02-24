#!/bin/bash

source scripts/multiArchMatrix.sh
source scripts/logger.sh

showHelp() {
	echo "Usage: $0 -i <Image name> -t <Tag name> -a <Target architecture> -b <Baseimage branch> -l -v <version> -r <VCS reference> -g <GitHub auth token>"
}

while getopts :hi:t:a:b:l:v:r:g: opt; do
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
		l)
			TAG_LATEST=$OPTARG
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
if [ $TAG_LATEST == "1" ]; then
	logSubTitle "Tag as latest: Yes"
else
	logSubTitle "Tag as latest: No"
fi
logSubTitle "Architecture: $ARCH"
logSubTitle "Baseimage branch: $BASEIMAGE_BRANCH"
logSubTitle "Image version: $VERSION"
logSubTitle "VCS reference: $VCS_REF"
echo ""

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

logTitle "Reading multiarch build settings"
PLATFORM=""
for i in ${!ARCHS[@]}; do
	if [ -z "$ARCH" ]; then
		PLATFORM+="linux/"
		PLATFORM+=${PLATFORMS[i]}
		PLATFORM+=","
		if [ "${TEST_ENABLED[i]}" == "1" ]; then
			TEST_ENABLE="true"
		else
			TEST_ENABLE="false"
		fi

		logNormal "Arch: ${ARCHS[i]}"
		logDetail "Docker arch: ${DOCKER_ARCHS[i]}"
		logDetail "Variant: ${ARCH_VARIANTS[i]}"
		logDetail "Qemu arch name: ${QEMU_ARCHS[i]}"
		logDetail "Docker platform name: linux/${PLATFORMS[i]}"
		[ "${TEST_ENABLED[i]}" == "1" ] && TEST_ENABLE="true" || TEST_ENABLE="false"
		logDetail "Testing enabled: $TEST_ENABLE"

	else
		if [ "${ARCHS[i]}" == "$ARCH" ]; then
			PLATFORM+="linux/"
			PLATFORM+=${PLATFORMS[i]}
			PLATFORM+=","
			logNormal "Arch: $ARCH"
			logDetail "Docker arch: ${DOCKER_ARCHS[i]}"
			logDetail "Variant: ${ARCH_VARIANTS[i]}"
			logDetail "Qemu arch name: ${QEMU_ARCHS[i]}"
			logDetail "Docker platform name: linux/${PLATFORMS[i]}"
			if [ "${TEST_ENABLED[i]}" == "1" ]; then
				TEST_ENABLE="true"
			else
				TEST_ENABLE="false"
			fi
			logDetail "Testing enabled: $TEST_ENABLE"
			break
		fi
	fi
done
PLATFORM=${PLATFORM%?};
# PLATFORM=$(echo "$PLATFORM" |sed 's/.$//')
logNormal "Build platform list: $PLATFORM"
logNormal "Done"

echo ""
logTitle "Checking/cleaning buildx environment"
docker buildx rm mybuilder
docker buildx create --driver-opt network=host --use --name mybuilder
docker buildx ls
docker buildx inspect --bootstrap
logNormal "Done"

echo ""
logTitle "Start building"
cmdBuild="docker buildx build"
cmdBuild+=" --platform $PLATFORM"
cmdBuild+=" --build-arg BUILD_DATE=$BUILD_DATE"
if [ ! -z $BASEIMAGE_BRANCH ]; then
	cmdBuild+=" --build-arg BASEIMAGE_BRANCH=$BASEIMAGE_BRANCH"
fi
if [ ! -z $VERSION ]; then
	cmdBuild+=" --build-arg VERSION=$VERSION"
fi
if [ ! -z $VCS_REF ]; then
	cmdBuild+=" --build-arg VCS_REF=$VCS_REF"
fi
cmdBuild+=" --tag $DOCKER_IMAGE:$DOCKER_TAG"
if [ $TAG_LATEST == "1" ]; then
	cmdBuild+=" --tag $DOCKER_IMAGE:latest"
fi
cmdBuild+=" --push"
cmdBuild+=" ."

logNormal "Build command:"
logDetail "$cmdBuild"
eval $cmdBuild
if [ $? != 0 ]; then
	logError "Build failed"
	exit 3
fi

logNormal "Build done"

echo ""
logTitle "Inspecting images just built"
docker buildx imagetools inspect $DOCKER_IMAGE:$DOCKER_TAG
if [ $TAG_LATEST == "1" ]; then
	echo ""
	docker buildx imagetools inspect $DOCKER_IMAGE:latest
fi
logNormal "Inspection done"
