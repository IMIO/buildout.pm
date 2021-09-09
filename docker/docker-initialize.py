#!/usr/local/bin/python
# -*- coding: utf-8 -*-

import re
import os
import warnings


class Environment(object):
    """ Configure container via environment variables
    """

    def __init__(
        self,
        env=os.environ,
        zope_conf="/plone/parts/instance1/etc/zope.conf",
        zeopack_conf="/plone/bin/zeopack",
        zeoserver_conf="/plone/parts/zeoserver/etc/zeo.conf",
        async_conf="/plone/parts/instance-async/etc/zope.conf",
    ):
        self.env = env
        self.zope_conf = zope_conf
        self.zeopack_conf = zeopack_conf
        self.zeoserver_conf = zeoserver_conf
        self.async_conf = async_conf
        self.parts = "/plone/parts/"

    def zeoclient(self, fname):
        """ ZEO Client
        """
        server = self.env.get("ZEO_ADDRESS", None)
        if not server:
            return

        config = ""
        with open(fname, "r") as cfile:
            config = cfile.read()

        read_only = self.env.get("ZEO_READ_ONLY", "false")
        zeo_ro_fallback = self.env.get("ZEO_CLIENT_READ_ONLY_FALLBACK", "false")
        shared_blob_dir = self.env.get("ZEO_SHARED_BLOB_DIR", "off")
        zeo_storage = self.env.get("ZEO_STORAGE", "1")
        zeo_client_cache_size = self.env.get("ZEO_CLIENT_CACHE_SIZE", "128MB")
        zeo_conf = ZEO_TEMPLATE.format(
            zeo_address=server,
            read_only=read_only,
            zeo_client_read_only_fallback=zeo_ro_fallback,
            shared_blob_dir=shared_blob_dir,
            zeo_storage=zeo_storage,
            zeo_client_cache_size=zeo_client_cache_size,
        )

        pattern = re.compile(r"<zeoclient>.+</zeoclient>", re.DOTALL)
        config = re.sub(pattern, zeo_conf, config)
        pattern = re.compile(r"%define ZEOADDRESS 8100", re.DOTALL)
        config = re.sub(pattern, "%define ZEOADDRESS {}".format(server), config)

        with open(fname, "w") as cfile:
            cfile.write(config)

    def fixtures(self):
        """ ZEO Client
        """
        # server = self.env.get("ZEO_ADDRESS", None)
        # if not server:
        #     return
        server = self.env.get("ZEO_ADDRESS", '8100')
        zeo_client_cache_size = self.env.get("ZEO_CLIENT_CACHE_SIZE", "2000MB")
        zodb_cache_size = self.env.get("ZODB_CACHE_SIZE", "300000")
        admin_password = self.env.get("ADMIN_PASSWORD", "admin")

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
            filedata = filedata.replace('ZEOADDRESS 8100', 'ZEOADDRESS ' + server)
            filedata = filedata.replace('cache-size 1000MB', 'cache-size ' + zeo_client_cache_size)
            filedata = filedata.replace('cache-size 100000', 'cache-size ' + zodb_cache_size)
            filedata = filedata.replace('password admin', 'password ' + admin_password)

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
        # self.zeoclient(self.zope_conf)
        # self.zeoclient(self.async_conf)
        self.fixtures()
        self.mountpoint()

    __call__ = setup


ZEO_TEMPLATE = """
    <zeoclient>
      read-only {read_only}
      read-only-fallback {zeo_client_read_only_fallback}
      blob-dir /plone/var/blobstorage
      shared-blob-dir {shared_blob_dir}
      server {zeo_address}
      storage {zeo_storage}
      name zeostorage
      var /plone/parts/instance1/var
      cache-size {zeo_client_cache_size}
    </zeoclient>
""".strip()


ZEODB="""
<zodb_db main>\n
    cache-size {zodb_cache_size}\n
    <zeoclient>\n
      read-only false\n
      read-only-fallback false\n
      blob-dir /data/blobstorage\n
      shared-blob-dir on\n
      server {zeo_address}\n
      storage 1\n
      name zeostorage\n
      var /plone/parts/instance1/var\n
      cache-size {zeo_client_cache_size}\n
    </zeoclient>\n
    mount-point /\n
</zodb_db>\n
""".strip()


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
