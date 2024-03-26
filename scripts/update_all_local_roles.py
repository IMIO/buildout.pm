from plone import api
from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
import logging

setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    tool = api.portal.get_tool("portal_plonemeeting")
    tool.update_all_local_roles(redirect=False)
