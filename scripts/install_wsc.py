from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from imio.webspellchecker import config as webspellchecker_config
from os import getenv
from plone import api
from Products.PloneMeeting import logger

import logging
import sys
import transaction


setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    logger.info("Installing webspellchecker...")
    WSC_JS_BUNDLE_URL = getenv("WSC_JS_BUNDLE_URL")
    WSC_SERVICE_URL = getenv("WSC_SERVICE_URL")
    if not WSC_JS_BUNDLE_URL or not WSC_SERVICE_URL:
        logger.error("Missing webspellchecker environment variables. Aborting installation.")
        sys.exit(-1)

    portal = api.portal.get()
    portal.portal_setup.runImportStepFromProfile(
        'profile-Products.PloneMeeting:default',
        'PloneMeeting-Install-Imio-Webspellchecker')
    webspellchecker_config.set_js_bundle_url(WSC_JS_BUNDLE_URL.decode('utf-8'))
    webspellchecker_config.set_service_url(WSC_SERVICE_URL.decode('utf-8'))
    transaction.commit()
    logger.info("Installed webspellchecker.")
