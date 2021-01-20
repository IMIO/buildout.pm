# -*- coding: utf-8 -*-
import logging
import transaction
from AccessControl.SecurityManagement import newSecurityManager
from Products.CMFCore.utils import getToolByName
from zope.component.hooks import setSite
from zope.globalrequest import setRequest
from Testing import makerequest
logger = logging.getLogger('create.plonesite')

site_id = 'demo'


def import_demo_profile(app):
    import ipdb
    ipdb.set_trace()
    acl_users = app.acl_users
    user = acl_users.getUser('admin')
    if user:
        user = user.__of__(acl_users)
        newSecurityManager(None, user)
        logger.info("Retrieved the admin user")

    plone = app.unrestrictedTraverse(site_id)
    plone = makerequest.makerequest(plone)
    # support plone.subrequest
    plone.REQUEST['PARENTS'] = [plone]
    setRequest(plone.REQUEST)
    setSite(plone)

    setup = getToolByName(plone, 'portal_setup')
    plone.setupCurrentSkin(plone.REQUEST)
    setup.runAllImportStepsFromProfile('profile-Products.MeetingCommunes:demo')


if __name__ == '__main__':
    import_demo_profile(app)