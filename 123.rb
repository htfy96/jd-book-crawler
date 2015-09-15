require 'net/http'
require 'nokogiri'
require 'sqlite3'

def fetch(http, uri_str, limit = 10)
        # You should choose a better exception.
        puts uri_str
        raise ArgumentError, 'too many HTTP redirects' if limit == 0
        request = Net::HTTP::Get.new URI(uri_str)

        response = http.request request

        case response
        when Net::HTTPSuccess then
                response.body
        end
end

db = SQLite3::Database.new "data.db"
STDOUT.sync = true
cnt = 0
db.execute("BEGIN")
Net::HTTP.start('item.jd.com',80) do |http|
        for i in 10006054..20000000 do
                puts "processing "+i.to_s
                STDOUT.flush
                doc = Nokogiri::HTML( fetch(http, 'http://item.jd.com/'+i.to_s+ '.html') )
                if /mbNav-1">图书/ =~ (doc.css('.breadcrumb').to_s.encode(Encoding::UTF_8))
                        begin
                                cnt = cnt +1
                                puts doc.css("#name>h1").to_s.encode(Encoding::UTF_8).gsub(/\n|<strong>|<\/strong>/,'')
                                db.execute("insert into items (id, name, imgsrc) VALUES (?,?,?)", [i,
                                                                                                   /<h1>(?<main>.*)<\/h1>/.match( doc.css("#name>h1").to_s.encode(Encoding::UTF_8).gsub(/\n|<strong>|<\/strong>/,'')
 )["main"].delete(" "),
                                                                                                   /src="\/\/(?<main>.*)" alt/.match( doc.css("#spec-n1>img").to_s.encode(Encoding::UTF_8) )["main"]])
                                if cnt > 20
                                        db.execute('COMMIT')
                                        db.execute('BEGIN')
                                        cnt = 0
                                end
                        rescue SQLite3::ConstraintException
                                warn("duplicate id: "+i.to_s)
                        rescue NoMethodError
                                warn("Matching failed")
                        ensure
                        end
                end
        end
        db.execute('COMMIT')
end

