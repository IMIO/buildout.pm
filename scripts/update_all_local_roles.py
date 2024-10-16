from collections import Iterable
from DateTime import DateTime
from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api
from Products.PloneMeeting.interfaces import IMeeting
from Products.PloneMeeting.interfaces import IMeetingItem

import json
import logging
import os
import transaction


def parse_query_date(query, key):
    if isinstance(query[key]['query'], str) or isinstance(query[key]['query'], unicode):
        query[key]['query'] = DateTime(query[key]['query'])
    elif isinstance(query[key]['query'], Iterable):
        for i, item in enumerate(query[key]['query']):
            query[key]['query'][i] = DateTime(item)


setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    tool = api.portal.get_tool("portal_plonemeeting")
    QUERY_CATALOG = os.environ.get('QUERY_CATALOG')
    brains = []
    if QUERY_CATALOG:
        catalog = api.portal.get_tool("portal_catalog")
        query = json.loads(QUERY_CATALOG)
        # Making sure we only update local roles on meetings and meetingitems
        query['object_provides'] = [IMeeting.__identifier__, IMeetingItem.__identifier__]
        if 'created' in query.keys() and "query" in query['created'].keys():
            parse_query_date(query, 'created')
        if 'modified' in query.keys() and "query" in query['modified'].keys():
            parse_query_date(query, 'modified')
        brains = catalog.unrestrictedSearchResults(**query)
    tool.update_all_local_roles(redirect=False, brains=brains)
    transaction.commit()
