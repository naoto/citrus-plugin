require 'sqlite3'
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'uri'

class LogSearch < Citrus::Plugin

  CREATESQL = 'CREATE TABLE "messages" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"channel" varchar(255),"user" varchar(255),"comment" varchar(255),"created_at" datetime,"updated_at" datetime);'

  CHECKSQL = 'SELECT count(*) FROM sqlite_master WHERE type="table" AND name=?'

  def initialize(*args)
    super

    @prefix = @config['prefix'] || 'log'
    @id = @config['user']
    @pass = @config['pass']
    @path = @config['path'] || 'plugins/log.sqlite3'

    @db = SQLite3::Database.new(@path) #unless File.exist?(@path)
    @db.busy_timeout(5000)

    begin
      @db.execute(CREATESQL)
    rescue SQLite3::SQLException => e
      puts e
    end
  end

  def on_privmsg(prefix,channel,message)

    case message
    when /^timeline[\s]{0,}([\d]+)$/
      res = newtimeline(channel,$1) || {}
      prefix =~ /^[^!]+/
      priv = "#{$&}@"
      /@(.+)$/ =~ channel
      priv << "#{$1}"
      res.each_with_index { |result,index|
        text = "#{result[0]}: #{result[1]} #{result[2]}"
        sleep 2
        privmsg(priv,text)
      }
    when /^#{@prefix}\snewtimeline[\s|]([0-9]+)$/
      res = newtimeline(channel,$1) || {}
      prefix =~ /^[^!]+/
      priv = "#{$&}@"
      /@(.+)$/ =~ channel
      priv << "#{$1}"
      res.each_with_index { |result,index|
        text = "#{result[0]}: #{result[1]} #{result[2]}"
        sleep 2
        privmsg(priv,text)
      }
    when /^#{@prefix}\s+(.+)?limit[\s|]([0-9]+)$/
      count = Integer($2)
      res = search(channel,$1) || {}
      prefix =~ /^[^!]+/
      priv = "#{$&}@"
      /@(.+)$/ =~ channel
      priv << "#{$1}"
      res.each_with_index { |result,index|
        break if index == count
        text = "#{result[0]}: #{result[1]} #{result[2]}"
        sleep 2
        privmsg(priv,text)
      }
    when /^#{@prefix}\s+(.+)$/
      res = search(channel,$1) || {}

      res.each_with_index { |result,index|
        break if index == 3
        text = "#{result[0]}: #{result[1]} #{result[2]}"
        notice(channel,text)
      }

      notice(channel,'しらなーい') if res.empty?
    when /^bookmark\s+(.+)$/
      res = bookmark(channel,$1) || {}

      res.each_with_index { |result,index|
        break if index == 3
        text = "#{result[0]}: #{result[1]} #{result[2]}"
        notice(channel,text)
      }

      notice(channel,'しらなーい') if res.empty?
    when /^ranking top(\d+)$/
      res = ranking(channel,$1) || {}

      res.each_with_index { |result,index|
        text = "#{result[0]} POST: #{result[1]}"
        notice(channel,text)
      }
    else
      write(prefix,channel,message)
    end
  end

  private
  def ranking(channel,count)
    sql = "select count(user) as cnt,user from messages where channel = '#{channel}' group by user,channel order by cnt DESC limit #{count}"

    result = @db.execute(sql) unless count.empty?
  end

  private
  def bookmark(channel,phrase)
    sql = "SELECT created_at,user,comment FROM messages WHERE channel='#{channel}' AND comment like '%http://%' "

    phrase.split(/\s+/).each { |word|
      word.gsub!(/'/){"''"}
      sql << "AND (comment like '%#{word}%' OR user like '%#{word}%' OR title like '%#{word}%') "
    }

    sql << 'ORDER BY id DESC'

    result = @db.execute(sql) unless phrase.empty?

  end

  private
  def newtimeline(channel,count)

    sql = "SELECT created_at,user,comment FROM messages WHERE channel='#{channel}' order by id DESC limit #{count}"
    result = @db.execute(sql) unless count.empty?

  end

  private
  def search(channel,phrase)

    sql = "SELECT created_at,user,comment FROM messages WHERE channel='#{channel}' AND "

    words = ''

    case phrase
    when /^name\s+is\s+(.+)$/

      words = $1.gsub(/'/){ "''" }
      sql << "user='#{words}' ORDER BY id DESC"

    else

      words = phrase
      if /^count\((.+)\)/ === phrase
        sql = "SELECT count(*) FROM messages WHERE channel='#{channel}' AND "
        words = $1
      end

      where = ''

      words.split(/\s+/).each { |word|
        word.gsub!(/'/) { "''" }
        where << ' AND ' unless where.empty?
        where << "(user LIKE '%#{word}%' OR comment LIKE '%#{word}%')"
      }

      sql << "#{where} ORDER BY id DESC"
    end

    result = @db.execute(sql) unless words.empty?

  end

  private
  def write(prefix,channel,message)

    title = ""
    if message =~ /(http[s]?\:\/\/[\w\+\$\;\?\.\%\,\!\#\~\*\/\:\@\&\\\=\_\-]+)/
       title = Nokogiri::HTML(open(URI.escape($1))).at("title").content || ""
    end
    [channel,message,title].each { |v| v.gsub!(/(?=['"\\])/) { '\\' } }

    p title
    prefix =~ /^[^!]+/
    sql = 'INSERT INTO messages(channel,user,comment,title,created_at,updated_at) VALUES (?,?,?,?,datetime("now","localtime"),datetime("now","localtime"))'
    @db.execute(sql,channel,$&,message,title)

  end
end

