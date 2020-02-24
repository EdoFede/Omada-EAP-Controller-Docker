#!/bin/bash

# SERVER_ARCH=$(uname -m) && \

# case "$SERVER_ARCH" in
# 	"x86_64" | "amd64" | "aarch64" | "i386" | "i686")
# 		apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E52529D4 && \
# 		apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B7C549A058F8B6B && \
# 		echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-4.2.list && \
# 		apt-get update && \
# 		apt-get install -y --no-install-recommends --allow-unauthenticated mongodb-org
# 		;;
# 	"ppc64le")
# 		apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E52529D4 && \
# 		apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B7C549A058F8B6B && \
# 		echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.3 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.3.list && \
# 		apt-get update && \
# 		apt-get install -y --no-install-recommends --allow-unauthenticated mongodb-org
# 		;;
# 	*)
# 		apt-get install -y --no-install-recommends mongodb
# 		;;
# esac

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E52529D4 && \
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 4B7C549A058F8B6B && \
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.3 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.3.list && \
apt-get update && \
apt-get install -y --no-install-recommends --allow-unauthenticated mongodb-org
