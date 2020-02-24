#!/bin/bash

echo ""
echo -e "\033[0;34m# Docker engine config file \033[0m"
sudo ls -la /etc/docker/daemon.json
sudo cat /etc/docker/daemon.json

echo -e "\033[0;34m# OLD Docker engine service file \033[0m"
ls -l /etc/systemd/system/multi-user.target.wants/docker.service
ls -l /lib/systemd/system/docker.service
sudo cat /lib/systemd/system/docker.service

echo ""
echo -e "\033[0;34m# Enabling Docker engine experimental mode \033[0m"
sudo sed -i -e 's/fd:\/\//fd:\/\/ --experimental=true/g' /lib/systemd/system/docker.service

echo -e "\033[0;34m# NEW Docker engine service file \033[0m"
ls -l /etc/systemd/system/multi-user.target.wants/docker.service
ls -l /lib/systemd/system/docker.service
sudo cat /lib/systemd/system/docker.service


echo ""
echo -e "\033[0;34m# Restarting Docker service \033[0m"
sudo systemctl daemon-reload
sudo systemctl restart docker


echo ""
echo -e "\033[0;34m# Checking Docker restart logs \033[0m"
echo -e "\033[0;32msystemctl status docker.service\033[0m"
sudo systemctl status docker.service


echo ""
echo -e "\033[0;34m# Enabling Docker client experimental mode \033[0m"
mkdir -p $HOME/.docker
echo '{"experimental":"enabled"}' | sudo tee $HOME/.docker/config.json

echo ""
echo -e "\033[0;34m# Checking docker version \033[0m"
docker version

echo ""
echo -e "\033[0;34m# Checking running containers \033[0m"
docker ps -a
