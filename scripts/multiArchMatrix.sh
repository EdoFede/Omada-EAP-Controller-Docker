#!/bin/bash

ARCHS=(			amd64	arm32v7	arm64v8	i386	ppc64le)
DOCKER_ARCHS=(	amd64	arm		arm		386		ppc64le)
ARCH_VARIANTS=(	NONE	v7		v8		NONE	NONE)
QEMU_ARCHS=(	NONE	arm		aarch64	i386	ppc64le)
TEST_ENABLED=(	1		1		1		1		1)
