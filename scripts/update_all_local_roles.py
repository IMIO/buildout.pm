from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api

import logging
import transaction


setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    tool = api.portal.get_tool("portal_plonemeeting")
    tool.update_all_local_roles(redirect=False)
    transaction.commit()
