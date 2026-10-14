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
    catalog = api.portal.get_tool("portal_catalog")
    cfg_id = os.environ.get("MEETING_CONFIG")
    cfgs = [tool.get(cfg_id)] if cfg_id else tool.objectValues("MeetingConfig")
    for cfg in cfgs:
        # Same logic as MeetingConfig.updateAdviceConfidentiality, without the redirect.
        confidentiality_default = cfg.getAdviceConfidentialityDefault()
        for brain in catalog.unrestrictedSearchResults(portal_type=cfg.getItemTypeName()):
            for advice in brain.getObject().adviceIndex.itervalues():
                advice["isConfidential"] = confidentiality_default
    transaction.commit()
