import logging

import transaction
from DateTime import DateTime
from imio.helpers.security import setup_app
from imio.helpers.security import setup_logger
from plone import api

NEW_HOLIDAY_DATES = [
    '2026/01/01',  # 2026
    '2026/04/06',
    '2026/05/01',
    '2026/05/14',
    '2026/05/25',
    '2026/07/21',
    '2026/08/15',
    '2026/09/27',
    '2026/11/01',
    '2026/11/11',
    '2026/11/15',
    '2026/12/25',
]

setup_logger(level=logging.INFO)
setup_app(app)
with api.env.adopt_user(username="admin"):
    logger = logging.getLogger()
    tool = api.portal.get_tool("portal_plonemeeting")
    logger.info('Updating holidays...')
    holiday_dates = [holiday['date'] for holiday in tool.getHolidays()]
    stored_holidays = list(tool.getHolidays())
    highest_stored_holiday = DateTime(stored_holidays[-1]['date'])
    for new_holiday_date in NEW_HOLIDAY_DATES:
        # update if not there and if higher that highest stored holiday
        if new_holiday_date not in holiday_dates and \
                DateTime(new_holiday_date) > highest_stored_holiday:
            stored_holidays.append({'date': new_holiday_date})
            logger.info('Adding {0} to holidays'.format(new_holiday_date))
    tool.setHolidays(stored_holidays)
    transaction.commit()
    logger.info('Done.')

