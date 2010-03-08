
class SimpleReply < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
		@config["replies"].each do |r|
			if message =~ /(#{r["words"]})/ &&
			   (!r["channels"] || r["channels"].include?(channel))

				notice channel, r["reply"]
			end
		end
	end
end

tests do

	describe SimpleReply do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhost")

			@plugin = SimpleReply.new(@core, { "SimpleReply" => {
				"replies" => [
					{
						"words"    => ["foo", "bar"],
						"channels" => "#test",
						"reply"    => "Nice boat.",
					}
				]
			} })
		end

		it "should reply correctly" do
			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "foo")
			@socket.pop.to_s.should == "NOTICE #test :Nice boat.\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "bar")
			@socket.pop.to_s.should == "NOTICE #test :Nice boat.\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "baz")
			@socket.should be_empty

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test2", "foo")
			@socket.should be_empty
		end
	end

end
