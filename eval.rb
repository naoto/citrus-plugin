
require "rubygems"
require "nkf"
begin
  gem "safeeval"
rescue Gem::LoadError; end
require "safe_eval"

class Eval < Citrus::Plugin
	def initialize(config, chokan)
		super
		@prefix = @config["prefix"] || "rb "
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel) 
		case message
		when /^#{Regexp.quote(@prefix)}(.+)$/i
			code = Regexp.last_match[1].taint.gsub(/\\([^\\])/){ $1 }
			ret = ""
			begin
				ret = SafeEval.eval(code).inspect
			rescue Exception => e
				ret = "#{e.class.name} => " + e.to_s.inspect
			end
			ret = ret.to_s[/.{200}/] + "..." if ret.scan(/./).size > 200
			notice(channel, ret.gsub(/\n/, " "))
		end
	end
end

Lambda = Proc
class Lambda
	def curry
		s = <<-EOS.unindent
			lambda {|al|
				args = [#{(1...self.arity).inject(""){|r,i|r<<"a#{i}, "}}al]
				self[*args]
			}
		EOS
		instance_eval (1...self.arity).inject(s) {|r,i|
			<<-EOS.unindent
				lambda {|a#{self.arity-1-i+1}|
					#{r}
				}
			EOS
		}
	end
end

S = lambda {|x, y, z| x[z][y[z]] }.curry
K = lambda {|x, y| x }.curry
I = lambda {|x| x } # S[K][K]


tests do

	describe Eval do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhsot")

			@plugin = Eval.new(@core, { "SimpleReply" => {
			} })
		end

		it "should reply correctly" do
			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "?rb 1")
			@socket.pop.to_s.should == "NOTICE #test 1\r\n"

			@socket.clear
			@plugin.on_privmsg(@prefix, "#test", "?rb raise 'foobar'")
			@socket.pop.to_s.should == "NOTICE #test :RuntimeError => \"(eval):1:in `safe_eval': foobar\"\r\n"
		end
	end

end
