ARG BASEIMAGE_BRANCH
FROM ubuntu:$BASEIMAGE_BRANCH

ARG OMADA_DOWNLOAD_LINK=https://static.tp-link.com/upload/software/2021/202108/20210813/Omada_SDN_Controller_v4.4.4_linux_x64.tar.gz

# Install required software
RUN	export LC_ALL=C && \
	export DEBIAN_FRONTEND=noninteractive && \
#	echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		apt-utils && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		bash \
		curl \
		vim \
		libcap-dev && \
	curl https://www.mongodb.org/static/pgp/server-3.6.asc | apt-key add - && \
	echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" > /etc/apt/sources.list.d/mongodb-org.list && \
	ln -s /bin/true /usr/local/bin/systemctl && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		openjdk-8-jre-headless \
		mongodb-org \
		net-tools && \
	ln -s /usr/lib/jvm/java-8-openjdk-* /usr/lib/jvm/default-java && \
	# Clean apt
	apt-get clean && \
	rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* && \
	# Install and configure Omada EAP Controller
	curl -o /tmp/Omada.tar.gz $OMADA_DOWNLOAD_LINK && \
	tar -zxvf /tmp/Omada.tar.gz -C /tmp/ && \
	rm /tmp/Omada.tar.gz && \
	mv $(find /tmp -maxdepth 1 -type d -name Omada*) /tmp/Omada && \
	mkdir -p /opt/EAP-Controller && \
	# Build program dir
	mv /tmp/Omada/* /opt/EAP-Controller/ && \
	ln -s /usr/bin/mongod /opt/EAP-Controller/bin/mongod && \
	mkdir /opt/EAP-Controller/logs && \
	mkdir /opt/EAP-Controller/work && \
	# Add OS user and group and fix permissions
	useradd -r -M -u 50124 -d /opt/EAP-Controller -c "EAP Controller user" -s /bin/false omada && \
	chgrp -R omada /opt/EAP-Controller && \
	chown -R omada /opt/EAP-Controller && \
	find /opt/EAP-Controller/ -type d -exec chmod 755 {} \; && \
	find /opt/EAP-Controller/ -type f -exec chmod 644 {} \;

USER omada
WORKDIR /opt/EAP-Controller/lib

CMD java \
	-server \
	-Xms128m \
	-Xmx1024m \
	-XX:MaxHeapFreeRatio=60 \
	-XX:MinHeapFreeRatio=30 \
	-XX:+HeapDumpOnOutOfMemoryError \
	-cp /usr/share/java/commons-daemon.jar:/opt/EAP-Controller/lib/* \
	com.tplink.omada.start.OmadaLinuxMain

HEALTHCHECK \
	--start-period=120s \
	--timeout=15s \
	--interval=60s \
	CMD curl --fail http://127.0.0.1:8088/status || exit 1

EXPOSE 8043/tcp 8088/tcp 8843/tcp 27001/udp 27002/tcp 29810/udp 29811/tcp 29812/tcp 29813/tcp
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
		org.label-schema.docker.cmd="docker create --name Omada-EAP-Controller --restart unless-stopped --env TZ=Europe/Rome --network host --volume omada_data:/opt/EAP-Controller/data --volume omada_logs:/opt/EAP-Controller/logs --volume omada_work:/opt/EAP-Controller/work edofede/omada-eap-controller:latest"
