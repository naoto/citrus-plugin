
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'

class Taihu < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
		DESCRIPTION
	end

	def initialize(*args)
		super
		@prefix = @config['prefix'] || '(台風|たいふう)どうなった'
		@number = @config['number'] || 3
		@limit  = @config['limit']  || 10
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		case message
		when /
			^
			#{@prefix}
		/x
			result = search
			result.each { |line| notice(channel, line) }
		end
	end

	private
	def search ()
		result   = Array.new
    html = Hpricot(open("http://typhoon.yahoo.co.jp/weather/jp/typhoon/typhb.html"))
    html.search("tr") { |tr|
      if /^(台風\d).+[^号]$/ =~ tr.innerText.strip.toutf8
        result << tr.innerText.strip.toutf8[0..250]
      end
    }
    result << "http://disaster.yahoo.co.jp/weather/1249345464/typhoon.yahoo.co.jp/weather/jp/typhoon/typha.jpg"
		result
	end
end
