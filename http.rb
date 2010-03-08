
require "pathname"
require "uri"

class HTTP < Citrus::Plugin

	attr_reader :handlers
	attr_reader :config

	def initialize(*args)
		super

		@handlers_dir = Pathname.new(@core.config.general["plugin_dir"]) + "http"
		eval( (@handlers_dir + "default.rb").read, nil, "default.rb")

		handlers = Pathname.glob(@handlers_dir + "*.rb")
		handlers.each do |f|
			next if f.basename == "default.rb"
			eval(f.read, nil, f)
		end

		plugin = self
		Handler.__send__(:define_method, :log) do |*args|
			plugin.log(*args)
		end

		@handlers = (@config["handlers"] + [{"Default" => {}}]).map {|h|
			Handler.handlers[h.keys.first].new(self)
		}
	end

	def on_privmsg(prefix, channel, message)
    return if @config["channels"].nil? || !@config["channels"].include?(channel)
		URI.extract(message, %w[http]) do |uri|
			Thread.start(channel, URI(uri)) do |chan, u|
				begin
					response(chan, u)
				rescue Exception => e
					post NOTICE, chan, e.inspect
					log e.inspect
					e.backtrace.each do |l|
						log l
					end
				end
			end
		end
	end

	def response(chan, uri)
		ret = nil
		@handlers.each do |handler|
			ret = handler.process(uri)
			break if ret
		end
		if ret
			post NOTICE, chan, ret
		end
	end

	class Handler
		@@handlers = {}

		def self.handlers
			@@handlers
		end

		def self.inherited(subclass)
			name = subclass.name.sub(/^.+::/, "")
			@@handlers[name] = subclass
		end

		def initialize(parent)
			@parent = parent
		end

		def process(uri)
		end
	end
end

tests do

	describe HTTP do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhsot")
			@handlers_dir = Pathname.tempname + "http"
			@handlers_dir.mkpath

			(@handlers_dir + "foo.rb").open("w") do |f|
				f.puts <<-EOF
					class Foo < Handler

						def process(uri)
							return unless uri.host == "foo"

							"foo foo"
						end
					end
				EOF
			end

			(@handlers_dir + "bar.rb").open("w") do |f|
				f.puts <<-EOF
					class Bar < Handler

						def process(uri)
							return unless uri.host == "bar"

							"bar bar"
						end
					end
				EOF
			end

			(@handlers_dir + "default.rb").open("w") do |f|
				f.puts File.read("./plugins/http/default.rb")
			end

			@core.config.general["plugin_dir"] = @handlers_dir.parent.to_s

			@plugin = HTTP.new(@core, { "HTTP" => {
				"handlers" => [
					{ "Foo" => nil },
					{ "Bar" => nil },
				],
				"whitelist" => [ "localhost" ],
			} })
		end

		it "should reply correctly" do
			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "http://foo/")
			@socket.pop.to_s.should == "NOTICE #test :foo foo\r\n"


			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "http://bar/")
			@socket.pop.to_s.should == "NOTICE #test :bar bar\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "http://example.com/")
			@socket.pop.to_s.should == "NOTICE #test :Example Web Page [text/html; charset=UTF-8]\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "http://www.google.co.jp/intl/ja/about.html")
			@socket.pop.to_s.should == "NOTICE #test :Google について [text/html]\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "http://192.168.0.1/")
			@socket.pop.to_s.should == "NOTICE #test :#<Net::HTTP::Paranoid::NotAllowedHostError: 192.168.0.1 is not allowed host>\r\n"
		end
	end

end

