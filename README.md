See example.py for usage in python2.

##Table structure

raw.db

|id: INT PRIMARY KEY NOT NULL | content : TEXT NOT NULL|

Note that content is compressed by Zlib, therefore zlib.decompress may be required. 
