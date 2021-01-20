# -*- coding: utf-8 -*-
import logging
import transaction
from zope.component.hooks import setSite
from zope.globalrequest import setRequest
from AccessControl.SecurityManagement import newSecurityManager
from Testing import makerequest
logger = logging.getLogger('create.plonesite')


def creat_default_mc_site(app, site_id):
    default_language = 'fr'
    app = makerequest.makerequest(app)
    # support plone.subrequest
    app.REQUEST['PARENTS'] = [app]
    setRequest(app.REQUEST)
    container = app.unrestrictedTraverse('/')

    acl_users = app.acl_users
    user = acl_users.getUser('admin')
    if user:
        user = user.__of__(acl_users)
        newSecurityManager(None, user)
        logger.info("Retrieved the admin user")

    # install plone site with cpskin
    oids = container.objectIds()
    if site_id not in oids:
        # create plone site
        from Products.CMFPlone.factory import addPloneSite
        extension_profiles = (
            'Products.MeetingCommunes:demo',
        )
        transaction.commit()
        addPloneSite(
            container,
            site_id,
            title="Site de {}".format(site_id),
            extension_ids=extension_profiles,
            setup_content=False,
            default_language=default_language
        )

        transaction.commit()
        logger.info("Added Plone Site")
        plone = getattr(container, site_id)
        setSite(plone)

        portal_languages = plone.portal_languages
        portal_languages.setDefaultLanguage(default_language)
        supported = portal_languages.getSupportedLanguages()
        portal_languages.removeSupportedLanguages(supported)
        portal_languages.addSupportedLanguage(default_language)
    else:
        logger.warning("A Plone Site <%= @project_id %> already exists and will not be replaced")

    # install cputils
    if not hasattr(app, 'cputils_install'):
        from Products.ExternalMethod.ExternalMethod import manage_addExternalMethod
        manage_addExternalMethod(app, 'cputils_install', '', 'CPUtils.utils', 'install')
        app.cputils_install(app)
        logger.info("Cpskin installed")


if __name__ == '__main__':
    creat_default_mc_site(app, 'demo')
