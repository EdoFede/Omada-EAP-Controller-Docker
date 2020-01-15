#!/bin/bash
# Logger functions

function logTitle() {
	echo -e "\033[0;34m######### $1 #########\033[0m"
}

function logSubTitle() {
	echo -e "\033[0;34m# $1 \033[0m"
}

function logNormal() {
	echo -e "\033[0;32m$1\033[0m"
}

function logError() {
	echo -e "\033[0;31m$1\033[0m"
}

function logDetail() {
	echo "   $1"
}
