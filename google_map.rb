
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'
require 'nkf'

class GoogleMap < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
			このプラグインは Google の API を利用しておらず、真っ黒です。
			絶対に利用しないでください。
			<http://www.google.com/accounts/TOS>
		DESCRIPTION
	end

	def initialize(*args)
		super
		@prefix = @config['prefix'] || 'ってどこ[?|？]{0,1}'
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
		uri      = URI.parse("http://maps.google.co.jp/maps?f=q&source=s_q&hl=ja&geocode=&q=#{keywords}")
		Net::HTTP.start(uri.host, uri.port) do |http|
			response = http.get(uri.request_uri)
			if response.code.to_i == 200 then
				document = Hpricot(response.body)
				document.search("span.adr").each { |node|
					break if result.size > 0
					line = "[#{NKF.nkf('-w8 --cp932',node.inner_text)}] "
          open("http://tinyurl.com/api-create.php?url=#{uri}") do |f|
            line << f.read()
          end
          result << line

				}
			end
      if result.empty?
        result << "わかんない #{uri}"
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

