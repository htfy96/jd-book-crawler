#encoding: utf-8
require 'net/http'
require 'sqlite3'
require 'nokogiri'
require 'zlib'

def fetch(http, uri_str, limit = 10)
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

db = SQLite3::Database.new "raw.db"
db.results_as_hash = true
STDOUT.sync = true
cnt = 0
start = 10000000    
db.execute('select * from books order by id desc limit 1') do |row|
        begin
                puts Zlib::Inflate.inflate(row['content'].force_encoding('utf-8'))
        rescue
        ensure
        end
end

begin
        db.execute('select * from books order by id desc limit 1') do |row|
                start = row['id'].to_s().to_i()
        end
rescue
        start = 10000000
ensure
end


puts "will now start from " + start.to_s()
db.execute("BEGIN")
Net::HTTP.start('item.jd.com',80) do |http|
        for i in start..11000000 do
                ss = fetch(http, 'http://item.jd.com/'+i.to_s+ '.html')
                doc = Nokogiri::HTML( ss )
                if /mbNav-1">图书/ =~ (doc.css('.breadcrumb').to_s.encode(Encoding::UTF_8))
                        puts "processing "+i.to_s
                        STDOUT.flush
                        begin
                                cnt = cnt+1
                                db.execute("insert into books (id, content) VALUES (?,?)", [i,Zlib::Deflate.deflate(doc.to_s.encode(Encoding::UTF_8))])
                                if cnt > 20
                                        db.execute('COMMIT')
                                        db.execute('BEGIN')
                                        cnt = 0
                                end
                        rescue SQLite3::ConstraintException
                                warn("duplicate id: "+i.to_s)
                        rescue NoMethodError
                                warn("Matching failed")
			rescue
                        ensure
                        end
                end
        end
        db.execute('COMMIT')
end

