#!/usr/bin/make
#
plone=$(shell grep plone-path port.cfg|cut -c 14-)
hostname=$(shell hostname)
instance1_port=$(shell grep instance1-http port.cfg|cut -c 18-)
all: run

.PHONY: bootstrap
bootstrap:
	virtualenv-2.7 .
	./bin/pip install setuptools==38.2.4
	./bin/python bootstrap.py --version=2.10.0

.PHONY: buildout
buildout:
	if test -f .installed.cfg;then rm .installed.cfg;fi
	if ! test -f bin/buildout;then make bootstrap;fi
	if ! test -f var/filestorage/Data.fs;then make standard-config; else bin/buildout;fi

.PHONY: standard-config
standard-config:
	if ! test -f bin/buildout;then make bootstrap;fi
	bin/buildout -t 5 -c standard-config.cfg

.PHONY: run
run:
	if ! test -f bin/instance1;then make buildout;fi
	bin/instance1 fg

.PHONY: upgrade
upgrade:
	if ! test -f bin/instance1;then make buildout;fi
	echo $(plone)
	echo $(hostname)
	echo $(instance1_port)
#	./copy-data.sh --disable-auth=1
	./bin/upgrade-portals --username admin -G profile-Products.MeetingCommunes:default $(plone)
	$ echo "Job done for instance $(plone), check http://$(hostname):$(instance1_port)/manage_main" | mail -s "Migration finished for $(plone)" pm-interne@imio.be

.PHONY: cleanall
cleanall:
	rm -fr lib bin develop-eggs downloads eggs parts .installed.cfg
