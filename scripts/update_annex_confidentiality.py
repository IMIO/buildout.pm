from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api

import logging
import os
import transaction


setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    tool = api.portal.get_tool("portal_plonemeeting")
    cfg_id = os.environ.get("MEETING_CONFIG")
    cfgs = [tool.get(cfg_id)] if cfg_id else tool.objectValues("MeetingConfig")
    # The MeetingConfig methods redirect to HTTP_REFERER at the end.
    tool.REQUEST.set("HTTP_REFERER", tool.absolute_url())
    for cfg in cfgs:
        cfg.updateAnnexConfidentiality()
    transaction.commit()
