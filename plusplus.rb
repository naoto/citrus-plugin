
require "yaml"

class Plusplus < Citrus::Plugin

	def initialize(config, chokan)
		super
		@datafile = datafile(@config["data"] || "plusplus.yaml")
		@least    = @config['least'] || 1
		@excludes = @config['excludes'] || []

		unless @datafile.exist?
			@datafile.open("w") {|f| YAML.dump({}, f) }
		end
	end

	def on_privmsg(prefix, channel, message)
		return unless @channels.nil? || !@channels.include?(channel)
		case message
		when /karma for (\S+)/
			nick = Regexp.last_match[1]
			notice_karma(channel, nick)

		when /\(([^)]{#{@least},})\)(\+\+|--)/, /([\w:]{#{@least},})(\+\+|--)/u
			nick, dir = Regexp.last_match.captures
			return if @excludes.include?(nick)

			@datafile.open("r+") do |f|
				data = YAML.load(f)
				(data[nick] ||= { "++" => 0, "--" => 0 })[dir] += 1
				f.rewind
				YAML.dump(data, f)
				f.truncate(f.tell)
			end

			notice_karma(channel, nick)
		end
	end

	def notice_karma(channel, nick)
		plus, minus = karma_for(nick)
		if plus
			karma = plus - minus
			notice(channel, "#{nick}: #{karma} (#{plus}++ #{minus}--)")
		else
			notice(channel, "don't know #{nick}")
		end
	end

	def karma_for(nick)
		data = @datafile.open {|f| YAML.load(f) }
		if data[nick]
			plus  = data[nick]["++"]
			minus = data[nick]["--"]
			[plus, minus]
		else
			nil
		end
	end
end

tests do

	describe Plusplus do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhsot")

			@plugin = Plusplus.new(@core, { "Plusplus" => {
			} })
		end

		it "should reply correctly" do
			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "foo++")
			@socket.pop.to_s.should == "NOTICE #test :foo: 1 (1++ 0--)\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "foo++")
			@socket.pop.to_s.should == "NOTICE #test :foo: 2 (2++ 0--)\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "foo--")
			@socket.pop.to_s.should == "NOTICE #test :foo: 1 (2++ 1--)\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "karma for foo")
			@socket.pop.to_s.should == "NOTICE #test :foo: 1 (2++ 1--)\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "(C++)++")
			@socket.pop.to_s.should == "NOTICE #test :C++: 1 (1++ 0--)\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "karma for C++")
			@socket.pop.to_s.should == "NOTICE #test :C++: 1 (1++ 0--)\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "karma for unk")
			@socket.pop.to_s.should == "NOTICE #test :don't know unk\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "文乃さん++")
			@socket.pop.to_s.should == "NOTICE #test :文乃さん: 1 (1++ 0--)\r\n"

		end
	end

end
