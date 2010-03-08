require './plugins/systemcheck.rb'

class System < Citrus::Plugin
	def initialize(*args)
		super

		if @config['operator'].kind_of?(String)
			@config['operator'] = Regexp.new(@config['operator'])
		end
	end

	def on_invite(prefix, nick, channel)
		return unless @config['operator'] === prefix
		join(channel)
	end

	def on_privmsg(prefix, channel, message)
		return unless @config['operator'] === prefix
		case message
		when /^reload(?:\s+([a-z]+))?$/i
			log "#{prefix}: call reloading"
			begin
				@core.reload_config
			rescue => e
				log e.message
			end
			name = Regexp.last_match[1]
			log name
			if name
				begin
					instances = [@core.reload_plugin(name)]
				rescue Citrus::Plugins::UnknownPlugin => e
					notice channel, e.message
					instances = []
				end
			else
				instances = @core.reload_plugins.values
			end
			if instances.empty?
				notice channel, "No plugins to reload."
			else
				reloaded = instances.map {|i|
					i.class.name.sub(/^.+::/, "")
				}.join(" ")
				notice channel, "Reloaded: " + reloaded
			end
    when /^status\scheck/
        notice channel, "Self Check..."
        s = SystemCheck.new
        ping = s.ping_check_local
        notice channel, "LocalPingCheck:"
        ping.each { |p|
          notice channel, " " + p
        }
        notice channel, "GlobalPingCheck:"
        ping = s.ping_check_server
        ping.each { |p|
          notice channel, " " + p
        }
        notice channel, "LoadAvelage:"
        l = s.load_avelage
        l.each { |l|
          notice channel, " " + l
        }

		when /^chokan: join to (\S+)(?: (\S+))?/
			chan, pass = Regexp.last_match.captures
			log "Joining to '#{chan}' with '#{pass}'"
			join(chan.to_s, pass.to_s)

		when "chokan: part"
			part(channel, "lambda....")

		when "operator?"
			notice channel, "You are an operator for me."

		when "Gem.clear_paths"
			r = Gem.clear_paths
			notice channel, "Gem.clear_paths #{r.inspect}"
		end
	end
end

tests do

	describe System do
		before do
			@core     = DummyCore.new({
				"plugins" => { "Foo" => nil, "Bar" => nil }
			})
			@pdir = Pathname.new(@core.config.general["plugin_dir"])

			%w(Foo Bar).each do |name|
				(@pdir + "#{name.downcase}.rb").open("w") do |f|
					f << <<-EOS.unindent
						require "thread"
						class #{name}
							include Net::IRC
							include Constants

							attr_reader :config

							def initialize(core, config)
								@core, @config = core, config[self.class.name.sub(/.+::/, "")] || {}
								@messages = {}
							end

							def method_missing(method, *args)
								@messages[method] = args
							end

							def m
								@messages
							end
						end
					EOS
				end
			end

			@socket   = @core.socket
			@prefix   = Net::IRC::Prefix.new("foo!foo@localhost")
			@prefixop = Net::IRC::Prefix.new("foo!bar@localhost")

			@plugin = System.new(@core, { "System" => {
				"operator" => "foo!bar@localhost",
			} })

			@core.init_plugins
		end

		it "should response to operator" do
			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "operator?")
			@socket.should be_empty

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "operator?")
			@socket.pop.to_s.should == "NOTICE #test :You are an operator for me.\r\n"

			@plugin = System.new(@core, { "System" => {
				"operator" => "foo!bar@.+",
			} })

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "operator?")
			@socket.pop.to_s.should == "NOTICE #test :You are an operator for me.\r\n"

			@plugin = System.new(@core, { "System" => {
				"operator" => /foo!bar@.+/,
			} })

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "operator?")
			@socket.pop.to_s.should == "NOTICE #test :You are an operator for me.\r\n"
		end

		it "can reload_plugins" do
			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "reload")
			@socket.pop.to_s.should match(/^NOTICE #test /)

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "reload Foo")
			@socket.pop.to_s.should match(/^NOTICE #test /)

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "reload Unknown")
			@socket.pop.to_s.should match(/^NOTICE #test /)

			def @core.reload_config
				raise "config error"
			end

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "reload")
			@socket.pop.to_s.should match(/^NOTICE #test /)
		end

		it "can operate join/part" do
			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "chokan: part")
			@socket.pop.to_s.should match(/^PART #test /)

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "chokan: join to #foobar")
			@socket.pop.to_s.should match(/^JOIN #foobar /)

			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "chokan: join to #foobar password")
			@socket.pop.to_s.should match(/^JOIN #foobar password/)
		end

		it "can Gem.clear_paths" do
			@socket.clear
			@plugin.on_privmsg(@prefixop, "#test", "Gem.clear_paths")
			@socket.pop.to_s.should match(/^NOTICE #test :Gem.clear_paths/)
		end
	end

end

