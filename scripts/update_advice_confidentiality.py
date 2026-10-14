from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api

import logging
import os
import transaction


logger = logging.getLogger("update_advice_confidentiality")


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
    catalog = api.portal.get_tool("portal_catalog")
    for cfg in get_configs(tool):
        # Same logic as MeetingConfig.updateAdviceConfidentiality, without the redirect.
        confidentiality_default = cfg.getAdviceConfidentialityDefault()
        brains = catalog.unrestrictedSearchResults(portal_type=cfg.getItemTypeName())
        total = len(brains)
        for i, brain in enumerate(brains, 1):
            item = brain.getObject()
            logger.info("%d/%d Initializing advices confidentiality of item at %s" %
                        (i, total, "/".join(item.getPhysicalPath())))
            for advice in item.adviceIndex.itervalues():
                advice["isConfidential"] = confidentiality_default
        logger.info("Done for '%s'." % cfg.getId())
    transaction.commit()
