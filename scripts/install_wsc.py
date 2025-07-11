from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from imio.webspellchecker import config as webspellchecker_config
from imio.webspellchecker.interfaces import IImioWebspellcheckerLayer
from os import getenv
from plone import api
from plone.browserlayer.utils import registered_layers
from Products.PloneMeeting import logger

import logging
import transaction


setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    logger.info("Installing webspellchecker...")
    portal = api.portal.get()
    portal.portal_setup.runImportStepFromProfile(
        'profile-Products.PloneMeeting:default',
        'PloneMeeting-Install-Imio-Webspellchecker')
    logger.info("Installed webspellchecker.")

    WSC_JS_BUNDLE_URL = getenv("WSC_JS_BUNDLE_URL")
    WSC_SERVICE_URL = getenv("WSC_SERVICE_URL")
    if WSC_SERVICE_URL:
        webspellchecker_config.set_service_url(WSC_SERVICE_URL.decode('utf-8'))
        logger.info("WSC_SERVICE_URL set to %s.", WSC_SERVICE_URL)
    if WSC_JS_BUNDLE_URL:
        webspellchecker_config.set_js_bundle_url(WSC_JS_BUNDLE_URL.decode('utf-8'))
        logger.info("WSC_JS_BUNDLE_URL set to %s.", WSC_JS_BUNDLE_URL)
    WSC_DISABLE = getenv("WSC_DISABLE")
    if WSC_DISABLE:
        webspellchecker_config.set_enabled(False)
        logger.info("Webspellchecker disabled.")
    # by default disable WSC in quickupload as it breaks added annexes
    webspellchecker_config.set_disable_autosearch_in(
        u'["#form-widgets-title", "#form-widgets-description", ".select2-focusser", ".select2-input"]')
    transaction.commit()
