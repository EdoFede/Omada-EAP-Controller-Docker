# Docker image for TP-Link Omada controller
A multi-arch Docker image to run Omada EAP/SDN controller

[![](https://images.microbadger.com/badges/image/edofede/omada-eap-controller.svg)](https://microbadger.com/images/edofede/omada-eap-controller "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/edofede/omada-eap-controller.svg)](https://github.com/EdoFede/Omada-EAP-Controller-Docker/releases)
[![](https://img.shields.io/docker/pulls/edofede/omada-eap-controller.svg)](https://hub.docker.com/r/edofede/omada-eap-controller)  
[![](https://img.shields.io/github/last-commit/EdoFede/BaseImage-Docker.svg)](https://github.com/EdoFede/Omada-EAP-Controller-Docker/commits/master)
[![Build Status](https://travis-ci.com/EdoFede/BaseImage-Docker.svg?branch=master)](https://travis-ci.com/EdoFede/Omada-EAP-Controller-Docker)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/1aba1d9b419b4baaab5d1381cd715dbd)](https://www.codacy.com/manual/EdoFede/Omada-EAP-Controller-Docker?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=EdoFede/Omada-EAP-Controller-Docker&amp;utm_campaign=Badge_Grade)  
[![](https://img.shields.io/github/license/EdoFede/Omada-EAP-Controller-Docker.svg)](https://github.com/EdoFede/Omada-EAP-Controller-Docker/blob/master/LICENSE)
[![](https://img.shields.io/badge/If%20you%20can%20read%20this-you%20don't%20need%20glasses-brightgreen.svg)](https://shields.io)

## Introduction
This Docker image is based on Ubuntu linux and is developed to run TP-Link Omada controller in an self-contained enviornment.

## Multi-Architecture
This image is built with multiple CPU architecture support.  
As stated in Docker best-practice, the image is tagged and released with current version tag for many cpu architectures and a manifest "general" version tag, which automatically points to the right architecture when you use the image.

I also add the "latest" manifest tag every time I release a new version.

Since there are some limitation starting with Omada v4.x, I've dropped the 32bit support starting on v2.0 release.
If you want to run this image on an ARM 32bit or i386, you can still use the v1.0 tag/release (which is updated to Omada 3.2.10)

## How to use
### Container creation
You can simply create and start a Docker container from the [image on the Docker hub](https://hub.docker.com/r/edofede/omada-eap-controller) by running:

```bash
ImageName=edofede/omada-eap-controller
ImageVersion=master
ContainerName=Omada-EAP-Controller

docker pull $ImageName:$ImageVersion

docker create --name $ContainerName \
--restart unless-stopped \
--env TZ=Europe/Rome \
--network host \
--volume omada_data:/opt/EAP-Controller/data \
--volume omada_logs:/opt/EAP-Controller/logs \
--volume omada_work:/opt/EAP-Controller/work \
$ImageName:$ImageVersion

docker start BaseImage
```
Then wait for the first bootstap (db creation) and access the Omada controller via the web interface:
```http
https://<Docker host/IP>:8043/
```
For example (my case):
```http
https://nas.local:8043/
```

### Set timezone
The image comes with tzdata already installed (and timzone setted to Europe/Rome).
To set a new timezone, simpy edit the container creation command, adapting the line ```--env TZ=Europe/Rome``` with your needs.

## Docker image details
The image is based on Ubuntu linux and mainly consist of:

* OpenJDK 8 (JRE headless)  
* MongoDB 3.6  
* [TP-Link Omada controller](https://www.tp-link.com/us/support/download/omada-software-controller/)  

All components are automatically configured by the Docker image
 
## Support me
I treat these free projects exactly like professional works and I'm glad to share it, with some of my knowledge, for free.

If you found my work useful and want to support me, you can donate me a little amount  
[![Donate](https://img.shields.io/badge/Donate-Paypal-2997D8.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=JA8LPLG38EVK2&source=url)