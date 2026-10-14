from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api
from Products.PloneMeeting.utils import getAdvicePortalTypeIds

import logging
import os
import transaction


setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    tool = api.portal.get_tool("portal_plonemeeting")
    cfg_id = os.environ.get("MEETING_CONFIG")
    cfgs = [tool.get(cfg_id)] if cfg_id else tool.objectValues("MeetingConfig")
    for cfg in cfgs:
        portal_types = [cfg.getItemTypeName(), cfg.getMeetingTypeName()] + getAdvicePortalTypeIds()
        cfg._updateAnnexConfidentiality(portal_types=portal_types)
    transaction.commit()
