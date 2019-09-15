import os

import psycopg2
from pgnotify import await_pg_notifications, get_dbapi_connection

DB_HOST = os.environ.get('DB_HOST', 'localhost')

CONNECT = f'postgresql://postgres:password@{DB_HOST}/study'

conn = psycopg2.connect(CONNECT)
cur = conn.cursor()

e = get_dbapi_connection(CONNECT)

print('Starting to wait notification')

for notification in await_pg_notifications(e, ['trait_change']):
    print(notification.channel)
    print(notification.payload)
    id = int(notification.payload)
    cur.execute("SELECT * FROM events where id=%s;", (id,))
    print(cur.fetchone())
