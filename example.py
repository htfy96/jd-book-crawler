# -*- coding: utf8 -*-

import sqlite3,zlib

db = sqlite3.connect('raw.db')
cur = db.cursor()

cur.execute('select * from books')
rows = cur.fetchall()

for row in rows:
    print 'id:', row[0], ' html:', zlib.decompress(row[1])

db.close()
