import logging

from DateTime import DateTime
from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api
from Products.PloneMeeting.migrations import Migrator
import transaction

NEW_HOLIDAY_DATES = [
    '2027/01/01',  # 2027
    '2027/03/29',
    '2027/05/01',
    '2027/05/06',
    '2027/05/17',
    '2027/07/21',
    '2027/08/15',
    '2027/09/27',
    '2027/11/01',
    '2027/11/11',
    '2027/11/15',
    '2027/12/25',
]

setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    logger = logging.getLogger()
    logger.info('Updating holidays...')
    portal = api.portal.get()
    migrator = Migrator(portal)
    migrator.updateHolidays(NEW_HOLIDAY_DATES)
    transaction.commit()
    logger.info('Done.')

