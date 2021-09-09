#!/usr/bin/env python
# -*- coding: utf-8 -*-
from Testing import makerequest
from zope.globalrequest import setRequest

import argparse
import logging
import transaction

logger = logging.getLogger('update_zope_admin_password')


def main(app, user_id):
    parser = argparse.ArgumentParser()

    parser.add_argument('-p', '--new-password', dest='new_password',
                        type=str, default='',
                        help='New zope admin password for Plone instance'
                        )
    parser.add_argument('-c', '--change_file', dest='change_file',
                        type=str, default='scripts/update-admin-password.py',
                        help='File use to zope'
                        )
    args = parser.parse_args()
    new_password = args.new_password

    app = makerequest.makerequest(app)
    # support plone.subrequest
    app.REQUEST['PARENTS'] = [app]
    setRequest(app.REQUEST)

    acl_users = app.acl_users
    user = acl_users.getUser(user_id)
    if user:
        # update zope password
        users = acl_users.users
        users.updateUserPassword(user_id, new_password)
        transaction.commit()
    else:
        logger.info('User {0} doesn\'t exists'.format(user_id))


if __name__ == '__main__':
    user_id = 'admin'
    main(app, user_id)
