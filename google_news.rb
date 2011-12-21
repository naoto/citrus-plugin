
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'

class GoogleNews < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
			このプラグインは Google の API を利用しておらず、真っ黒です。
			絶対に利用しないでください。
			<http://www.google.com/accounts/TOS>
		DESCRIPTION
	end

 def initialize(*args)
    super
    @prefix = @config['prefix'] || '(の)?ニュース教えて'
    @keyword
    @limit = 3
  end

  def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
    case message
    when /^(ヘッドライン|最新|)#{@prefix}/
      getHeadline().each do |m|
        notice(channel, m)
      end
    when /^[\s]{0,}(.+)#{@prefix}/i
      searchNews(Regexp.last_match[1]).each do |m|
        notice(channel, m)
      end
    end
  end

  private
  def searchNews(query)
    # 検索
    query  = URI.encode(query)
    search = "http://news.google.com/news?hl=ja&ned=us&ie=UTF-8&oe=UTF-8&output=rss&q=#{query}"
    messages = getNews(search)
    return messages
  end

  def getHeadline()
    # 最新ニュース
    headline = "http://news.google.com/news?hl=ja&ned=us&ie=UTF-8&oe=UTF-8&output=rss&topic=h"
    messages = getNews(headline)
    return messages
  end

  def getNews(target)
    messages = Array.new()
    rss = open(target){ |file| RSS::Parser.parse(file.read) }
    rss.items[0...@limit].each do |item|
      title = item.title
      #url   = open("http://tinyurl.com/api-create.php?url=#{item.link}").read
      url   = URI.short_uri(item.link,"tiny")
      date  = item.date.strftime("%m月%d日 %H時")
      message = "#{date} #{title} #{url}"
      messages << message
    end
    return messages
  end
end
