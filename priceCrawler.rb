#encoding: utf-8
require 'net/http'
require 'sqlite3'
require 'zlib'
require 'json'
require 'thread'

def fetch(http, uri_str, limit = 3)
        # You should choose a better exception.
        puts uri_str
        return '' if limit == 0
        request = Net::HTTP::Get.new URI(uri_str)

        response = http.request request

        case response
        when Net::HTTPSuccess then
                response.body
        else
                fetch(http, uri_str, limit-1)
        end

rescue Timeout::Error 
        fetch(http, uri_str, limit-1)
rescue Zlib::BufError
        fetch(http, uri_str, limit-1)
end

db = SQLite3::Database.new "price.db"
db.results_as_hash = true
STDOUT.sync = true
$cnt = 0
start = 10000000    
db.execute('select * from prices order by id desc limit 1') do |row|
        begin
                puts Zlib::Inflate.inflate(row['content'].force_encoding('utf-8'))
        rescue
        ensure
        end
end

begin
        db.execute('select * from prices order by id desc limit 1') do |row|
                start = row['id'].to_s().to_i()
        end
rescue
        start = 10000000
ensure
end

$mutex = Mutex.new
$cntMutex = Mutex.new
$threadCnt = 0
def parsePrice( i, db)
        ss = fetch(Net::HTTP.start('p.3.cn',80), 'http://p.3.cn/prices/get?skuid=J_'+i.to_s)
        doc = JSON.parse(ss)[0]
        puts "processing "+i.to_s
        STDOUT.flush
        begin
                $mutex.synchronize {
                        $cnt = $cnt+1
                        db.execute("insert into prices (id, price) VALUES (?,?)", [i,doc["p"].to_f])
                        if $cnt > 20
                                db.execute('COMMIT')
                                db.execute('BEGIN')
                                $cnt = 0
                        end
                }
        rescue SQLite3::ConstraintException
                warn("duplicate id: "+i.to_s)
        rescue NoMethodError
                warn("Matching failed")
        rescue
                raise
        ensure
        end

        $cntMutex.synchronize {
                $threadCnt -= 1;
        }
end



puts "will now start from " + start.to_s()
db.execute("BEGIN")

Thread.new {
        for i in start..12000000 do

                sleep 0.1 while $threadCnt > 7

                $cntMutex.synchronize {
                        $threadCnt += 1;
                }
                Thread.new { 
                        parsePrice( i, db)
                }.run()

                
                
        end
        db.execute('COMMIT')
} . join
