#!/usr/local/bin/python
# -*- coding: utf-8 -*-
import os


class Environment(object):
    """ Configure container via environment variables
    """

    def __init__(
        self,
        env=os.environ,
    ):
        self.env = env
        self.parts = "/plone/parts/"

    def fixtures(self):
        """ ZEO Client
        """
        server = self.env.get("ZEO_ADDRESS", '8100')
        url = self.env.get("PUBLIC_URL", 'http://localhost/PM')
        zeo_client_cache_size = self.env.get("ZEO_CLIENT_CACHE_SIZE", "2000MB")
        zodb_cache_size = self.env.get("ZODB_CACHE_SIZE", "300000")
        admin_password = self.env.get("ADMIN_PASSWORD", "admin")
        plone_path = self.env.get("PLONE_PATH", "PM")

        directories = ['instance1/etc/zope.conf',
                       'instance2/etc/zope.conf',
                       'instance3/etc/zope.conf',
                       'instance4/etc/zope.conf',
                       'instance-debug/etc/zope.conf',
                       'instance-async/etc/zope.conf',
                       'instance-amqp/etc/zope.conf',
                       'zeoserver/etc/zeo.conf',
                       ]
        for directory in directories:
            file_path = self.parts + directory
            with open(file_path) as file:
                filedata = file.read()
            filedata = filedata.replace('server 8100', 'server ' + server)
            filedata = filedata.replace('http://localhost/Plone', url)
            filedata = filedata.replace('ZEOADDRESS 8100', 'ZEOADDRESS ' + server)
            filedata = filedata.replace('$(ZEO_ADDRESS)', server)
            filedata = filedata.replace('cache-size 1000MB', 'cache-size ' + zeo_client_cache_size)
            filedata = filedata.replace('cache-size 100000', 'cache-size ' + zodb_cache_size)
            filedata = filedata.replace('password admin', 'password ' + admin_password)
            filedata = filedata.replace('Plone/@@cron-tick', plone_path + '/@@cron-tick ')

            with open(file_path, 'w') as file:
                file.write(filedata)

    def mountpoint(self):
        mountpoint = self.env.get("MOUNTPOINT", "")
        if not mountpoint:
            return

        with open("/plone/zeo_add.conf", 'w') as file:
            file.write(ZEO_ADD.format(mountpoint=mountpoint))

        zodb_cache_size = self.env.get("ZEO_CLIENT_CACHE_SIZE", "1000MB")
        with open("/plone/zope_add_zeo.conf", 'w') as file:
            file.write(ZOPE_ADD_ZEO.format(mountpoint=mountpoint, cache=zodb_cache_size))

    def setup(self, **kwargs):
        self.fixtures()
        self.mountpoint()

    __call__ = setup


ZEO_ADD = """
<filestorage {mountpoint}>\n
  path $FILESTORAGE/{mountpoint}.fs\n
  blob-dir $BLOBSTORAGE-{mountpoint}\n
</filestorage>\n
""".strip()


ZOPE_ADD_ZEO = """
<zodb_db {mountpoint}>\n
  <zeoclient>\n
    blob-dir $BLOBSTORAGE-{mountpoint}\n
    shared-blob-dir on\n
    server $ZEOADDRESS\n
    storage {mountpoint}\n
    name {mountpoint}_zeostorage\n
    var $ZEOINSTANCE/var\n
    cache-size {cache}\n
  </zeoclient>\n
  mount-point /{mountpoint}\n
</zodb_db>\n
""".strip()


def initialize():
    """ Configure Plone instance as ZEO Client
    """
    environment = Environment()
    environment.setup()


if __name__ == "__main__":
    initialize()
