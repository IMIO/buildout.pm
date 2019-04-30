#!/usr/bin/make
#
plone=$(shell grep plone-path port.cfg|cut -c 14-)
cluster=$(shell grep cluster port.cfg|cut -c 11-)
hostname=$(shell hostname)
instance1_port=$(shell grep instance1-http port.cfg|cut -c 18-)
profile:=communes
product:=MeetingCommunes

all: run

.DEFAULT_GOAL:=help

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: bootstrap
bootstrap:  ## Creates virtualenv and instal requirements.txt
	virtualenv-2.7 .
	bin/python bin/pip install -r requirements.txt

.PHONY: buildout
buildout:  ## Run bootstrap if needed and  build the buildout
	if test -f .installed.cfg;then rm .installed.cfg;fi
	if ! test -f bin/buildout;then make bootstrap;fi
	if ! test -f var/filestorage/Data.fs;then make standard-config; else bin/python bin/buildout;fi

.PHONY: standard-config
standard-config:  ## Create a stadard plone site
	if ! test -f bin/buildout;then make bootstrap;fi
	bin/python bin/buildout -t 5 -c standard-config.cfg

.PHONY: run
run:  ## Run buildout if needed and start instance1 in foregroud
	if ! test -f bin/instance1;then make buildout;fi
	bin/python bin/instance1 fg

.PHONY: upgrade
upgrade:
	git fetch --tags
	git checkout $(shell git describe --tags)

	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-m buildout \
	-s restart \
	-d

	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-a 8 \
	-e pm-interne@imio.be \
	-f upgrade profile-Products.CMFPlone:plone \
	-f upgrade profile-Products.$(product):default \
	-d

.PHONY: cleanall
cleanall:  ## Clear build artefacts
	rm -fr lib bin develop-eggs downloads eggs parts .installed.cfg include

.PHONY: jenkins
jenkins: bootstrap  ## Same as buildout but for jenkins use only
	# can be run by example with: make jenkins profile='communes'
	sed -ie "s#communes#$(profile)#" jenkins.cfg
	bin/python bin/buildout -c jenkins.cfg

IMAGE_NAME=buildout.pm:test

eggs:  ## Copy eggs from docker image to speed up docker build
	-docker run --entrypoint='' $(IMAGE_NAME) tar -c -C /home/imio/.buildout eggs | tar x
	mkdir -p eggs

.PHONY: dockerbuild
dockerbuild: eggs  ## Build docker image
	docker build . -t $(IMAGE_NAME)

dockerbuild-cache:  ## Build docker base image
	docker build . -t buildout.pm:cache -f Dockerfile-cache
