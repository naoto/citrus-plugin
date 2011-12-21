
class Ping < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
		if message =~ /#{@config["prefix"]}/ &&
		   (!@config["channels"] || @config["channels"].include?(channel))

       site = $1
       ping_result = `ping -c 2 #{site.gsub(/\||\>/,"")}`.split(/\n/).reverse.take(2).reverse

			notice channel, ping_result.join
		end
	end
end
