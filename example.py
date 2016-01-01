# -*- coding: utf8 -*-
from __future__ import print_function
import sqlite3,zlib
from bs4 import BeautifulSoup
import codecs
import urllib2
import json

db = sqlite3.connect('raw_real.db')
cur = db.cursor()

info = sqlite3.connect('info.db')
infocur = info.cursor()

startid = 10000153
print("sucks1")
cur.execute('select * from books where id>?', str(startid))
cnt = 0

while True:
    cnt += 1
    if cnt > 50:
        info.commit()
        cnt = 0
    row = cur.fetchone()
    if row == None: break
    try:
        html = BeautifulSoup(zlib.decompress(row[1]), from_encoding="utf-8")
        # f.write(html.prettify())
        print(html.find('div', id="name").find('h1').get_text(strip=True))
        print(json.load(urllib2.urlopen('http://p.3.cn/prices/get?skuid=J_'+str(row[0])))[0]['p'])
        print('http:'+html.find('div', id='spec-n1').find('img')['src'])
        print(html.find('div', id='p-author').get_text(strip=True))
        print('http://item.jd.com/'+str(row[0])+'.html')
        print(html.find('div', class_='breadcrumb').find('span').get_text(strip=True)[1:-1])
        print(html.find('ul', id='parameter2').get_text(strip=True))
        print(row[0])
        infocur.execute("INSERT INTO info VALUES (?,?,?,?,?,?,?,?)", (row[0], \
            html.find('div', id="name").find('h1').get_text(strip=True), \
            json.load(urllib2.urlopen('http://p.3.cn/prices/get?skuid=J_'+str(row[0])))[0]['p'], \
            'http:'+html.find('div', id='spec-n1').find('img')['src'], \
            html.find('div', id='p-author').get_text(strip=True), \
            'http://item.jd.com/'+str(row[0])+'.html', \
            html.find('div', class_='breadcrumb').find('span').get_text(strip=True)[1:-1], \
            html.find('ul', id='parameter2').get_text(strip=True)))
    except Exception as e:
        print(e)


db.close()
info.close()
