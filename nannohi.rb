
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'
require 'kconv'
require 'nokogiri'
require 'open-uri'

class Nannohi < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
		DESCRIPTION
	end

	def initialize(*args)
		super
		@prefix = @config['prefix'] || '(今日|きょう)は(なん|何)の(日|ひ)[？?]{0,1}'
		@number = @config['number'] || 3
		@limit  = @config['limit']  || 10
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		case message
		when /
			^
			#{@prefix}
			$
		/x
			result = search()
			notice(channel, result)
		end
	end

	private
	def search ()
    result = ""
    h = Nokogiri::HTML(open(URI.encode("http://contents.kids.yahoo.co.jp/today/index.html")))
    h.search("#dateDtl").each { |l|
       result = l.inner_text()
    }
		return result
	end
end

tests do
	describe GoogleSearch do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhsot")

			@plugin = GoogleSearch.new(@core, { "GoogleSearch" => {
			} })
		end
	end

end

