#!/usr/local/bin/python
# -*- coding: utf-8 -*-
import os
import re


class Environment(object):
    """ Configure container via environment variables
    """

    def __init__(
        self,
        env=os.environ,
    ):
        self.env = env
        self.server = env.get("ZEO_ADDRESS", '8100')
        self.url = env.get("PUBLIC_URL", 'http://localhost/PM')
        self.zeo_client_cache_size = env.get("ZEO_CLIENT_CACHE_SIZE", "2000MB")
        self.zodb_cache_size = env.get("ZODB_CACHE_SIZE", "300000")
        self.admin_password = env.get("ADMIN_PASSWORD", "admin")
        self.plone_path = env.get("PLONE_PATH", "PM")
        self.mq_client_id = env.get("MQ_CLIENT_ID", "019999")
        self.mq_ws_url = env.get("MQ_WS_URL", "019999")
        self.mq_ws_login = env.get("MQ_WS_LOGIN", "testuser")
        self.mq_ws_password = env.get("MQ_WS_PASSWORD", "test")
        self.hostname = env.get('HOSTNAME')

        self.instance1_conf = '/plone/parts/instance/etc/zope.conf'
        self.instance_amqp_conf = '/plone/parts/instance-amqp/etc/zope.conf'
        self.instance_async_conf = '/plone/parts/instance-async/etc/zope.conf'
        self.instance_cron_conf = '/plone/parts/instance-cron/etc/zope.conf'
        self.instance_debug_conf = '/plone/parts/instance-debug/etc/zope.conf'
        self.zeoserver_conf = '/plone/parts/zeoserver/etc/zeo.conf'

    def _fix(self, path, activate_big_bang):
        with open(path) as file:
            filedata = file.read()
        filedata = re.sub(r'server.*?8100', 'server ' + self.server, filedata)
        filedata = filedata.replace('http://localhost/Plone', self.url)
        filedata = re.sub(r'ZEOADDRESS.*?8100', 'ZEOADDRESS ' + self.server, filedata)
        filedata = filedata.replace('$(ZEO_ADDRESS)', self.server)
        filedata = re.sub(r'cache-size.*?1000MB', 'cache-size ' + self.zeo_client_cache_size, filedata)
        filedata = re.sub(r'cache-size.*?100000', 'cache-size ' + self.zodb_cache_size, filedata)
        filedata = filedata.replace('Plone/@@cron-tick', self.plone_path + '/@@cron-tick ')
        filedata = re.sub(r'ACTIVE_BIGBANG.*?(True|False)', 'ACTIVE_BIGBANG ' + str(activate_big_bang), filedata)
        filedata = re.sub(r'path /data/log/instance.*.log', 'path /data/log/' + self.hostname + '.log', filedata)
        filedata = re.sub(r'path /plone/var/log/instance.*-Z2.log',
                          'path /data/log/' + self.hostname + '-Z2.log',
                          filedata)
        filedata = re.sub(r'SITE_ID .*', 'SITE_ID ' + self.plone_path, filedata)
        return filedata

    def _fix_conf(self, path, activate_big_bang):
        filedata = self._fix(path, activate_big_bang)
        filedata = re.sub(r'password.*?admin', 'password ' + self.admin_password, filedata)
        with open(path, 'w') as file:
            file.write(filedata)

    def _fix_amqp(self, activate_big_bang=False):
        filedata = self._fix(self.instance_amqp_conf, activate_big_bang)
        mq_host = self.env.get('MQ_HOST', '127.0.0.1')
        mq_port = self.env.get('MQ_PORT', '5672')
        mq_login = self.env.get('MQ_LOGIN', 'guest')
        mq_password = self.env.get('MQ_PASSWORD', 'guest')

        filedata = re.sub(r'site_id.*?Plone', 'site_id ' + self.plone_path, filedata)
        filedata = re.sub(r'client_id.*?019999', 'client_id ' + self.mq_client_id, filedata)
        filedata = re.sub(r'routing_key.*?019999', 'routing_key ' + self.mq_client_id, filedata)

        filedata = re.sub(r'ws_url.*?http://localhost:6543', 'ws_url ' + self.mq_ws_url, filedata)
        filedata = re.sub(r'ws_login.*?testuser', 'ws_login ' + self.mq_ws_login, filedata)
        filedata = re.sub(r'ws_password.*?test', 'ws_password ' + self.mq_ws_password, filedata)

        filedata = re.sub(r'hostname.*?127.0.0.1', 'hostname ' + mq_host, filedata)
        filedata = re.sub(r'port.*?5672', 'port ' + mq_port, filedata)
        filedata = re.sub(r'^ *password*?guest', 'password ' + mq_password, filedata)
        filedata = re.sub(r'username.*?guest', 'username ' + mq_login, filedata)

        with open(self.instance_amqp_conf, 'w') as file:
            file.write(filedata)

    def fixtures(self):
        """ ZEO Client
        """
        self._fix_conf(self.instance1_conf, False)
        self._fix_conf(self.instance_async_conf, False)
        self._fix_conf(self.instance_cron_conf, True)
        # instance debug doesn't exist in dev env
        if os.path.exists(self.instance_debug_conf):
            self._fix_conf(self.instance_debug_conf, False)
        self._fix_conf(self.zeoserver_conf, False)
        self._fix_amqp()

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
