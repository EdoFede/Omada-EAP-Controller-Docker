ARG ARCH
ARG BASEIMAGE_BRANCH
FROM $ARCH/ubuntu:$BASEIMAGE_BRANCH

COPY build_tmp/qemu/ /usr/bin/

ARG OMADA_DOWNLOAD_LINK=https://static.tp-link.com/2019/201911/20191108/Omada_Controller_v3.2.4_linux_x64.tar.gz

# Install required software
RUN	export LC_ALL=C && \
	export DEBIAN_FRONTEND=noninteractive && \
	echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		apt-utils && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		bash \
		curl \
		vim \
		libcap-dev \
		openjdk-8-jre-headless \
		jsvc \
		net-tools && \
	# Install mongodb from ext repository
	echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-4.0.list && \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E52529D4 && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		mongodb && \
	# Clean apt
	apt-get clean && \
	rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
	# Install and configure Omada EAP Controller
	curl -o /tmp/Omada.tar.gz $OMADA_DOWNLOAD_LINK && \
	tar -zxvf /tmp/Omada.tar.gz -C /tmp/ && \
	rm /tmp/Omada.tar.gz && \
	mv $(find /tmp -maxdepth 1 -type d -name Omada*) /tmp/Omada && \
	mkdir -p /opt/EAP-Controller && \
	mkdir -p /opt/EAP-Controller/bin && \
	mkdir -p /opt/EAP-Controller/logs && \
	mkdir -p /opt/EAP-Controller/work && \
	# Build program dir
	mv /tmp/Omada/readme.txt /opt/EAP-Controller/ && \
	mv /tmp/Omada/data /opt/EAP-Controller/ && \
	mv /tmp/Omada/keystore /opt/EAP-Controller/ && \
	mv /tmp/Omada/lib /opt/EAP-Controller/ && \
	mv /tmp/Omada/properties /opt/EAP-Controller/ && \
	mv /tmp/Omada/webapps /opt/EAP-Controller/ && \
	ln -s /usr/bin/mongod /opt/EAP-Controller/bin/mongod && \
	# Add OS user and group and fix permissions
	groupadd omada && \
	useradd -g omada -d /opt/EAP-Controller omada && \
	chgrp -R omada /opt/EAP-Controller && \
	chown -R omada /opt/EAP-Controller/data /opt/EAP-Controller/keystore /opt/EAP-Controller/properties /opt/EAP-Controller/logs /opt/EAP-Controller/work && \
	find /opt/EAP-Controller/ -type d -exec chmod 755 {} \; && \
	find /opt/EAP-Controller/ -type f -exec chmod 644 {} \; && \
	chmod 600 /opt/EAP-Controller/keystore/*

USER omada
WORKDIR /opt/EAP-Controller

CMD java \
	-client \
	-Xms128m \
	-Xmx768m \
	-XX:MinHeapFreeRatio=30 \
	-XX:MaxHeapFreeRatio=60 \
	-XX:+HeapDumpOnOutOfMemoryError \
	-cp /usr/share/java/commons-daemon.jar:/opt/EAP-Controller/lib/* \
	-Deap.home=/opt/EAP-Controller \
	com.tp_link.eap.start.EapLinuxMain

HEALTHCHECK \
	--start-period=120s \
	--timeout=15s \
	--interval=60s \
	CMD curl --fail http://127.0.0.1:8088 || exit 1

EXPOSE 8043/tcp 8088/tcp 27001/udp 27002/tcp 29810/udp 29811/tcp 29812/tcp 29813/tcp
VOLUME ["/opt/EAP-Controller/data", "/opt/EAP-Controller/logs", "/opt/EAP-Controller/work"]


ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

LABEL 	maintainer="Edoardo Federici <hello@edoardofederici.com>" \
		org.label-schema.schema-version="1.0.0-rc.1" \
		org.label-schema.vendor="Edoardo Federici" \
		org.label-schema.url="https://edoardofederici.com" \
		org.label-schema.name="omada-eap-controller" \
		org.label-schema.description="TP-Link Omada EAP Controller lightweight Docker image" \
		org.label-schema.version=$VERSION \
		org.label-schema.build-date=$BUILD_DATE \
		org.label-schema.vcs-url="https://github.com/EdoFede/Omada-EAP-Controller" \
		org.label-schema.vcs-ref=$VCS_REF \
		org.label-schema.docker.cmd="docker create --name Omada-EAP-Controller --env TZ=Europe/Rome --network host --volume omada_data:/opt/EAP-Controller/data --volume omada_logs:/opt/EAP-Controller/logs --volume omada_work:/opt/EAP-Controller/work edofede/omada-eap-controller:latest"
