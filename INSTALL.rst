We assume the installation in the folder /srv/instances/buildout.pm
 (that can be changed) and on an ubuntu distribution.
Your real username must replace in our commands the string "username".
Each command, specified by the symbol ">", can be executed
 (without the symbol >).

First we become root
> sudo -s

We install the necessary libraries
> apt-get install build-essential
> apt-get install libreadline6-dev
> apt-get install zlib1g-dev (support zlib)
> apt-get install libjpeg62-dev
> apt-get install subversion
> apt-get install libpq-dev
> apt-get install libxml2-dev
> apt-get install libxslt1-dev
> apt-get install libbz2-dev
> apt-get install git
> apt-get install bzr

Needed by documentviewer product:
> apt-get install rubygems
> gem install docsplit
> apt-get install graphicsmagick
> apt-get install poppler-utils

We work in the folder /srv
> cd /srv

We change the owner of the folder to avoid continue working as root
> chown -R username:username .

We leave the user root.
> exit

We create some directories
> mkdir install
> mkdir instances
> cd install

We install python2.7 that will be used to run the buildout and zope instance
> wget http://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz
> tar xvzf Python-2.7.16.tgz
> cd Python-2.7.16
> ./configure --prefix=/srv/python27
> make
> make install

We install the python utility easy_install
> cd /srv/install
> wget http://peak.telecommunity.com/dist/ez_setup.py
> /srv/python27/bin/python ez_setup.py

We install the python utility virtualenv
> /srv/python27/bin/easy_install virtualenv

We can define a cache for buildout
See http://www.imio.be/support/documentation/tutoriels/utilisation-dun-buildout/definition-dun-cache-pour-buildout/

We download the buildout files in our folder
> cd /srv/instances
> git clone git@github.com:IMIO/buildout.pm.git
> cd buildout.pm

We modify the Makefile file to indicate the real path of the virtualenv utility.
To do that, you can edit the file in a simple text editor.
It's necessary to replace the line "virtualenv27 --no-site-packages ." by
    "/srv/python27/bin/virtualenv --no-site-packages ."
OR
You can create a link to our virtualenv without modifying Makefile
    "sudo ln -s /srv/python27/bin/virtualenv /usr/local/bin/virtualenv-2.7"

We initialize the buildout.
> make buildout

We start the zeo server.
> bin/zeoserver start
Then the zope instance.
> bin/instance1 fg
