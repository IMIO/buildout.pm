#!/usr/bin/make
#
plone=$(shell grep plone-path port.cfg|cut -c 14-)
cluster=$(shell grep cluster port.cfg|cut -c 11-)
hostname=$(shell hostname)
instance1_port=$(shell grep instance1-http port.cfg|cut -c 18-)
profile:=communes
product:=MeetingCommunes

all: run

.PHONY: bootstrap
bootstrap:
	virtualenv-2.7 .
	bin/python bin/pip install -r requirements.txt

.PHONY: buildout
buildout:
	if test -f .installed.cfg;then rm .installed.cfg;fi
	if ! test -f bin/buildout;then make bootstrap;fi
	if ! test -f var/filestorage/Data.fs;then make standard-config; else bin/python bin/buildout;fi

.PHONY: standard-config
standard-config:
	if ! test -f bin/buildout;then make bootstrap;fi
	bin/python bin/buildout -t 5 -c standard-config.cfg

.PHONY: run
run:
	if ! test -f bin/instance1;then make buildout;fi
	bin/python bin/instance1 fg

.PHONY: upgrade
upgrade:
	git fetch --tags
	git checkout $(shell git describe --tags)
	rm -f make.log
	
	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-m buildout \
	-d
	
	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-s restart \
	-d

	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-a 0 \
	-d
	
	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-a 8 \
	-e pm-interne@imio.be \
	-f upgrade profile-Products.CMFPlone:plone \
	-f upgrade profile-Products.$(product):default \
	-d
	
	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-a 1 \
	-d

.PHONY: cleanall
cleanall:
	rm -fr lib bin develop-eggs downloads eggs parts .installed.cfg

.PHONY: jenkins
jenkins: bootstrap
	# can be run by example with: make jenkins profile='communes'
	sed -ie "s#communes#$(profile)#" jenkins.cfg
	bin/python bin/buildout -c jenkins.cfg
