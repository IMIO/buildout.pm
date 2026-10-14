from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api

import logging
import os
import transaction


logger = logging.getLogger("update_personal_labels")


def get_configs(tool):
    cfg_id = os.environ.get("MEETING_CONFIG")
    if not cfg_id:
        return tool.objectValues("MeetingConfig")
    cfg = tool.get(cfg_id)
    if cfg is None or cfg.meta_type != "MeetingConfig":
        raise ValueError("MeetingConfig '%s' not found" % cfg_id)
    return [cfg]


# PERSONAL_LABELS is a comma-separated list of label ids.
personal_labels = [
    label.strip() for label in os.environ.get("PERSONAL_LABELS", "").split(",") if label.strip()]
if not personal_labels:
    raise ValueError("PERSONAL_LABELS is empty, give at least one personal label id")
modified_since_days = int(os.environ.get("MODIFIED_SINCE_DAYS", 30))

setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    tool = api.portal.get_tool("portal_plonemeeting")
    for cfg in get_configs(tool):
        # Use only the labels that are personal labels of this MeetingConfig.
        cfg_labels = [term.value for term in cfg.get_labels_vocab()]
        labels = [label for label in personal_labels if label in cfg_labels]
        if not labels:
            logger.info("No personal label %s in '%s', skipped" % (", ".join(personal_labels), cfg.getId()))
            continue
        logger.info("Updating personal labels %s of '%s'" % (", ".join(labels), cfg.getId()))
        updated = cfg._updatePersonalLabels(labels, modified_since_days)
        logger.info("%d item(s) updated in '%s'" % (updated, cfg.getId()))
    transaction.commit()
