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
	if test -f /usr/bin/virtualenv-2.7;then virtualenv-2.7 .;else virtualenv -p python2 .;fi
	make install-requirements

install-requirements:
	bin/python bin/pip install -r requirements.txt

.PHONY: buildout
buildout:
	echo "Starting Buildout on $(shell date)"
	if test -f .installed.cfg;then rm .installed.cfg;fi
	if ! test -f bin/buildout;then make bootstrap;fi
	# reinstall requirements in case it changed since last bootstrap
	make install-requirements
	if ! test -f var/filestorage/Data.fs;then make standard-config; else bin/python bin/buildout;fi
	echo "Finished on $(shell date)"

.PHONY: standard-config
standard-config:
	if ! test -f bin/buildout;then make bootstrap;fi
	bin/python bin/buildout -t 5 -c standard-config.cfg

.PHONY: run
run: buildout
	#if ! test -f bin/instance1;then make buildout;fi
	bin/zeoserver stop
	bin/zeoserver start
	bin/python bin/instance1 fg

.PHONY: refresh-tag
refresh-tag:
	git fetch -fv --tags
	make checkout
	make buildout
	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-s restart \
	-d

checkout:
	git checkout $(shell git describe --tags)

.PHONY: upgrade
upgrade:refresh-tag
	rm -f make.log
	~/imio.updates/bin/update_instances \
	-p $(cluster) \
	-a 8 \
	-e pm-interne@imio.be \
	-f upgrade _all_ \
	-d

.PHONY: cleanall
cleanall:
	rm -fr bin include lib local share develop-eggs downloads eggs parts .installed.cfg

.PHONY: jenkins
jenkins: bootstrap
	# can be run by example with: make jenkins profile='communes'
	sed -ie "s#communes#$(profile)#" jenkins.cfg
	bin/python bin/buildout -c jenkins.cfg

.PHONY: libreoffice
libreoffice:
	soffice '--accept=socket,host=localhost,port=2002;urp;StarOffice.ServiceManager' --nologo --headless --nofirststartwizard --norestore
