#!/usr/bin/make
#
plone=$(shell grep plone-path port.cfg|cut -c 14-)
cluster=$(shell grep cluster port.cfg|cut -c 11-)
hostname=$(shell hostname)
instance1_port=$(shell grep instance1-http port.cfg|cut -c 18-)
profile:=communes
product:=MeetingCommunes

test_suite:=testmc

all: run

.DEFAULT_GOAL:=help

help:  ## Displays this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: bootstrap
bootstrap:  ## Creates virtualenv and installs requirements.txt
	if test -f /usr/bin/virtualenv-2.7;then virtualenv-2.7 .;else virtualenv -p python2 .;fi
	make install-requirements

install-requirements:
	bin/python bin/pip install -r requirements.txt

.PHONY: buildout
buildout:  ## Runs bootstrap if needed and builds the buildout
	echo "Starting Buildout on $(shell date)"
	if test -f .installed.cfg;then rm .installed.cfg;fi
	if ! test -f bin/buildout;then make bootstrap; else make install-requirements;fi
	# reinstall requirements in case it changed since last bootstrap
	if ! test -f var/filestorage/Data.fs; then make standard-config;fi
	bin/python bin/buildout -t 120
	echo "Finished on $(shell date)"

.PHONY: standard-config
standard-config:  ## Creates a standard plone site
	if ! test -f bin/buildout;then make bootstrap;fi
	bin/python bin/buildout -t 120 -c standard-config.cfg

.PHONY: run
run: buildout  ## Runs buildout if needed and starts instance1 in foregroud
	#if ! test -f bin/instance1;then make buildout;fi
	bin/zeoserver stop
	bin/zeoserver start
	bin/python bin/instance1 fg

.PHONY: cleanall
cleanall:  ## Clears build artefacts and virtualenv
	rm -fr bin include lib local share develop-eggs downloads eggs parts .installed.cfg .git/hooks/pre-commit

.PHONY: jenkins
jenkins: bootstrap  ## Same as buildout but for jenkins use only
	# can be run by example with: make jenkins profile='communes'
	sed -ie "s#communes#$(profile)#" jenkins.cfg
	bin/python bin/buildout -c jenkins.cfg annotate
	bin/python bin/buildout -c jenkins.cfg

.PHONY: libreoffice
libreoffice:  ## Starts a LibreOffice server daemon process using locally installed LibreOffice
	soffice '--accept=socket,host=localhost,port=2002;urp;StarOffice.ServiceManager' --nologo --headless --nofirststartwizard --norestore

.PHONY: libreoffice-docker
libreoffice-docker:  ## Start a LibreOffice server on port 2002
	make stop-libreoffice-docker
	docker run -p 2002:2002\
                -d \
                --rm \
                --name="oo_server" \
                -v /tmp:/tmp \
                -v /var/tmp:/var/tmp \
                imiobe/libreoffice:6.4
	docker ps

.PHONY: stop-libreoffice-docker
stop-libreoffice-docker:  ## Kills the LibreOffice server
	if docker ps | grep oo_server;then docker stop oo_server;fi

.PHONY: copy-data
copy-data:  ## Makes a back up of local data and copies the Data.fs and blobstorage from a production server. I.E. to copy the demo instance use "make copy-data server=pm-prod24 buildout=demo_pm41"
	mv var var-$(shell date +"%d-%m-%Y-%T")
	mkdir -p var/blobstorage var/filestorage
	scripts/copy-data.sh -s=$(server) -b=$(buildout)

.PHONY: test
test:
	make libreoffice-docker
	if test -z "$(args)" ;then bin/$(test_suite);else bin/$(test_suite) -t $(args);fi

.PHONY: vc
vc:
	bin/versioncheck -rbo checkversion.html
