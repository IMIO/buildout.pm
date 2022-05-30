#!/usr/bin/make
#
SHELL := /bin/bash

plone=$(shell grep plone-path port.cfg|cut -c 14-)
cluster=$(shell grep cluster port.cfg|cut -c 11-)
hostname=$(shell hostname)
instance1_port=$(shell grep instance1-http port.cfg|cut -c 18-)
profile:=communes
package:=Products.MeetingCommunes
testSuite:=testmc

test_suite:=testmc

args = $(filter-out $@,$(MAKECMDGOALS))

all: run

.DEFAULT_GOAL:=help

help:  ## Displays this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install-requirements:
	rm -f .installed.cfg .mr.developer.cfg
	virtualenv -p python2 .
	bin/python bin/pip install -r requirements.txt
	# initilize CUSTOM_TMP directory
	mkdir -p -m 777 /tmp/appy

.PHONY: buildout
buildout: install-requirements  ## Runs bootstrap if needed and builds the buildout
	if test -z $(args) ; then time bin/python bin/buildout ; else time bin/python bin/buildout -c $(args) ; fi

.PHONY: run
run:  ## Runs buildout if needed and starts instance1 in foregroud
	if test -z "$(args)" ;then make buildout;else make buildout "$(args)";fi
	bin/zeoserver stop
	bin/zeoserver start
	make libreoffice-docker
	bin/python bin/instance1 fg

.PHONY: cleanall
cleanall:  ## Clears build artefacts and virtualenv
	if test -f var/zeoserver.pid; then kill -15 $(cat var/zeoserver.pid);fi
	if test -f var/instance1.pid; then kill -15 $(cat var/instance1.pid);fi
	rm -fr bin include lib local share develop-eggs downloads eggs parts .installed.cfg .mr.developer.cfg .git/hooks/pre-commit var/tmp

.PHONY: jenkins
jenkins: install-requirements  ## Same as buildout but for jenkins use only
	# can be run by example with: make jenkins profile='communes'
	sed -ie "s#communes#$(profile)#" jenkins.cfg
	sed -ie "s#Products.PloneMeeting#$(package)#" jenkins.cfg
	sed -ie "s#bin/test#bin/$(testSuite)#" jenkins.cfg
	bin/python bin/buildout -c jenkins.cfg annotate
	bin/python bin/buildout -c jenkins.cfg

.PHONY: libreoffice
libreoffice:  ## Starts a LibreOffice server daemon process using locally installed LibreOffice
	soffice '--accept=socket,host=localhost,port=2002;urp;StarOffice.ServiceManager' --nologo --headless --nofirststartwizard --norestore

.PHONY: libreoffice-docker
libreoffice-docker:  ## Start a LibreOffice server on port 2002
	make stop-libreoffice-docker
	docker run -p 127.0.0.1:2002:2002\
				--pull \
                --rm \
                -u 0:0 \
                --name="oo_server" \
                -v /tmp:/tmp/ \
                -d \
                imiobe/libreoffice:7.3 \
                soffice '--accept=socket,host=0.0.0.0,port=2002;urp;StarOffice.ServiceManager' --nologo --headless --nofirststartwizard --norestore
	docker ps

.PHONY: stop-libreoffice-docker
stop-libreoffice-docker:  ## Kills the LibreOffice server
	if docker ps | grep oo_server;then docker stop oo_server;fi

.PHONY: copy-data
copy-data:  ## Makes a back up of local data and copies the Data.fs and blobstorage from a production server. I.E. to copy the demo instance use "make copy-data server=pm-prod24 buildout=demo_pm41"
	if [[ -d var ]];then mv var var-$(shell date +"%d-%m-%Y-%T");fi;
	mkdir -p var/{blobstorage,filestorage}
	scripts/copy-data.sh -s=$(server) -b=$(buildout)

.PHONY: test
test:
	make libreoffice-docker
	if test -z "$(args)" ;then bin/$(test_suite);else bin/$(test_suite) -t $(args);fi

.PHONY: vc
vc:
	bin/versioncheck -rbo checkversion.html

.PHONY: ctop
ctop:  ## Runs A CTop instance to monitor the running docker container.
	docker run --rm -ti --pull always -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop:latest
