
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'

class GoogleSearch < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
			このプラグインは Google の API を利用しておらず、真っ黒です。
			絶対に利用しないでください。
			<http://www.google.com/accounts/TOS>
		DESCRIPTION
	end

	def initialize(*args)
		super
		@prefix = @config['prefix'] || '探して(き|来)て'
		@number = @config['number'] || 3
		@limit  = @config['limit']  || 10
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		case message
		when /
			^
			(.+)?                  (?# 3: search words)
			#{@prefix}
			$
		/x
			words  = $1
			#number = $1 && $1.to_i ||
			#         $2 && $2.scan(@prefix).size + 1
			result = search words
			result.each { |line| notice(channel, line) }
		end
	end

	private
	def search (string, shu=nil)
		result   = Array.new
		keywords = string.split(/\s+/).collect{ |item| URI.escape(item, /[^-.!~*'()\w]/n) }.join('+')
		number   = shu.nil? || shu.zero? ? @number : shu <= @limit ? shu : @limit
		uri      = URI.parse("http://www.google.co.jp/search?q=#{keywords}&ie=utf-8&oe=utf-8&lr=lang_ja&num=#{number}")
    p uri
		Net::HTTP.start(uri.host, uri.port) do |http|
			response = http.get(uri.request_uri)
			if response.code.to_i == 200 then
				document = Hpricot(response.body)
				document.search("h3.r").each { |node|
					break if result.size >= number
					result << "[#{node.inner_text}] #{node.at('a').attributes['href']}"
				}
			end
		end
		result
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

		it "should reply correctly" do
#					@socket.clear
#					@plugin.on_privmsg(@prefix, "#test", "foo")
#					@socket.pop.to_s.should == "NOTICE #test :Nice boat.\r\n"
		end
	end

end

