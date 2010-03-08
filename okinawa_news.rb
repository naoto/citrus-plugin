
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'
require 'time'

class OkinawaNews < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
			このプラグインは Google の API を利用しておらず、真っ黒です。
			絶対に利用しないでください。
			<http://www.google.com/accounts/TOS>
		DESCRIPTION
	end

   def initialize(*args)
    super
    @prefix = @config['prefix'] || '沖縄のニュース教えて'
    @keyword
  end

  def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
    case message
    when /#{@prefix}/i
      getShimpo.each do |m|
        notice(channel, m)
      end
      end
  end

  private
  def getShimpo()
    messages = Array.new()
    rss = Hpricot(open('http://rss.ryukyushimpo.jp/rss/ryukyushimpo/index.rdf').read)

    (rss/:item)[0...3].each do |i|
      title = i.search('title').inner_html
      url   = URI.short_uri(i.search('guid').inner_html,"tiny")
      date  = i.search('pubdate').inner_html
      if title.match(/!\[CDATA\[PR/)
      else
        date = Time.parse(date).strftime("%m月%d日 %H時")
        message = "#{date} #{title} #{url}"
        messages << message
      end
    end
    return messages
  end
end
