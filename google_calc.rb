require 'net/http'
require 'uri'

class GoogleCalc < Citrus::Plugin
	HYDE = 156.0000000

	def initialize(*args)
		HYDE.is_a?(Numeric) && HYDE === 156.0
		super
		@prefix = @config['prefix'] || 'c '
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		case message
		when /^#{@prefix}(.+)$/
			notice(channel, parse(Regexp.last_match[1]))
		end
	end

	private
	def parse(syntax)
		in_hyde = false

		syntax.gsub!(/([\d.,_]+) *hyde/) { "#{$1.to_i * HYDE.to_i}cm" }
		if syntax =~ /hyde/
			in_hyde = true
			syntax.sub!('hyde', 'cm')
		end

		Net::HTTP.start('www.google.co.jp', 80) do |http|
			uri = "/search?q=#{URI.encode(syntax, /[^-.!~*'()\w]/n)}&oe=utf-8&num=1"
			log uri
			response = http.get(uri)
			log response.inspect
			if %r{<h2\s[^>]+><b>(.+?)</b>}.match(response.body)
				ret = Regexp.last_match[1].gsub(/<sup>/, '^').gsub(/<[^>]*>/, '').gsub(/&#215;/, '*')
				ret.sub!(/= (\S+) cm/) { '= ' + ($1.gsub(/[^.\d]+/, '').to_f / HYDE).to_s + ' hyde' } if in_hyde
				ret.gsub(/(\d) (?=\d)/, '\\1,')
			else
				'わかんなーい'
			end
		end
	end
end

tests do
	describe GoogleCalc do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhsot")

			@plugin = GoogleCalc.new(@core, { "GoogleCalc" => {
			} })
		end

		it "should reply correctly" do
#					@socket.clear
#					@plugin.on_privmsg(@prefix, "#test", "foo")
#					@socket.pop.to_s.should == "NOTICE #test :Nice boat.\r\n"
		end
	end

end

