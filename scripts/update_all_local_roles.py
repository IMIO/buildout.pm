from plone import api
from imio.helpers.security import setup_logger
import logging

if __name__ == '__main__':
    setup_logger(level=logging.INFO)
    with api.env.adopt_user(username="admin"):
        tool = api.portal.get_tool("portal_plonemeeting")
        tool.update_all_local_roles(redirect=False, log_batch=1000)