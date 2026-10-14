from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api
from Products.PloneMeeting.utils import getAdvicePortalTypeIds

import logging
import os
import transaction


logger = logging.getLogger("update_annex_confidentiality")


def get_configs(tool):
    cfg_id = os.environ.get("MEETING_CONFIG")
    if not cfg_id:
        return tool.objectValues("MeetingConfig")
    cfg = tool.get(cfg_id)
    if cfg is None or cfg.meta_type != "MeetingConfig":
        raise ValueError("MeetingConfig '%s' not found" % cfg_id)
    return [cfg]


setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    tool = api.portal.get_tool("portal_plonemeeting")
    for cfg in get_configs(tool):
        logger.info("Updating annex confidentiality of '%s'" % cfg.getId())
        portal_types = [cfg.getItemTypeName(), cfg.getMeetingTypeName()]
        portal_types += getAdvicePortalTypeIds()
        cfg._updateAnnexConfidentiality(portal_types=portal_types)
    transaction.commit()
