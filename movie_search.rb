
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'

class MovieSearch < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
    ？
		DESCRIPTION
	end

	def initialize(*args)
		super
		@prefix = @config['prefix'] || '[^映][^画]見たい'
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
      notice(channel, "みつかんないよ") if result.empty?
		end
	end

	private
	def search (string, shu=nil)
		result   = Array.new
		keywords = string.split(/\s+/).collect{ |item| URI.escape(item, /[^-.!~*'()\w]/n) }.join('+')
		number   = shu.nil? || shu.zero? ? @number : shu <= @limit ? shu : @limit
		uri      = URI.parse("http://say-move.org/comesearch.php?q=#{keywords}&sort=view&genre=&sitei=&mode=&p=1")
		Net::HTTP.start(uri.host, uri.port) do |http|
			response = http.get(uri.request_uri)
			if response.code.to_i == 200 then
				document = Hpricot(response.body)
				document.search("a").each { |node|
          next unless /^http:\/\/say-move.org\/comeplay.php/ =~ node.attributes['href']
          next unless  node.search("img").empty?
					break if result.size >= number
					result << "[#{node.inner_text}] #{node.attributes['href']}"
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

