#!/bin/bash

source scripts/multiArchMatrix.sh
source scripts/logger.sh

TAG_LATEST=0

showHelp() {
	echo "Usage: $0 -i <Image name> -t <Tag name> [-l] (Adds latest tag)"
}

while getopts :hi:t:l opt; do
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
		l)
			TAG_LATEST=1
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
logTitle "Push parameters"
logSubTitle "Docker image: $DOCKER_IMAGE"
logSubTitle "Docker tag: $DOCKER_TAG $([ $TAG_LATEST == 1 ] && echo "(latest)")"
echo ""

# Push all builded images to Docker HUB
logTitle "Start pushing images"
for i in ${!ARCHS[@]}; do
	docker push $DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]}
	if [ $? != 0 ]; then
		logError "Error pushing $DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]}"
		exit 2
	fi
done
logNormal "Done"

### Main tag ###
logTitle "Start pushing manifest"
# Create manifest
cmdCreate="docker manifest create --amend $DOCKER_IMAGE:$DOCKER_TAG "
for i in ${!ARCHS[@]}; do
	cmdCreate+="$DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]} "
done
eval $cmdCreate
if [ $? != 0 ]; then
	logError "Error creating manifest $DOCKER_IMAGE:$DOCKER_TAG"
	exit 2
fi

# Annotate manifest
for i in ${!ARCHS[@]}; do
	cmdAnnotate="docker manifest annotate $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]}"
	cmdAnnotate+=" --os linux"
	cmdAnnotate+=" --arch ${DOCKER_ARCHS[i]}"
	if [[ "${ARCH_VARIANTS[i]}" != "NONE" ]]; then
		cmdAnnotate+=" --variant ${ARCH_VARIANTS[i]}"
	fi
	eval $cmdAnnotate
	if [ $? != 0 ]; then
		logError "Error annotating manifest $DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]}"
		exit 2
	fi
done
# Push manifest to Docker HUB
docker manifest push --purge $DOCKER_IMAGE:$DOCKER_TAG
if [ $? != 0 ]; then
	logError "Error pushing manifest $DOCKER_IMAGE:$DOCKER_TAG"
	exit 2
fi
logNormal "Done"

### Latest tag ###
if [ $TAG_LATEST == 1 ] ; then
	logTitle "Start pushing manifest (for latest tag)"
	# Create latest manifest
	cmdCreate="docker manifest create --amend $DOCKER_IMAGE:latest "
	for i in ${!ARCHS[@]}; do
		cmdCreate+="$DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]} "
	done
	eval $cmdCreate
	
	# Annotate manifest
	for i in ${!ARCHS[@]}; do
		cmdAnnotate="docker manifest annotate $DOCKER_IMAGE:latest $DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]}"
		cmdAnnotate+=" --os linux"
		cmdAnnotate+=" --arch ${DOCKER_ARCHS[i]}"
		if [[ "${ARCH_VARIANTS[i]}" != "NONE" ]]; then
			cmdAnnotate+=" --variant ${ARCH_VARIANTS[i]}"
		fi
		eval $cmdAnnotate
		if [ $? != 0 ]; then
			logError "Error annotating manifest $DOCKER_IMAGE:$DOCKER_TAG-${ARCHS[i]}"
			exit 2
		fi
	done
	# Push latest manifest to Docker HUB
	docker manifest push --purge $DOCKER_IMAGE:latest
	if [ $? != 0 ]; then
		logError "Error pushing manifest $DOCKER_IMAGE:latest"
		exit 2
	fi
	logNormal "Done"
fi
