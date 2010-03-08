require 'kconv'
class Kill < Citrus::Plugin
	def on_privmsg(prefix, channel, message)
	  if message =~ /(#{@config["words"]})/ &&
			 (!@config["channels"] || @config["channels"].include?(channel))
      
      poster = prefix.sub(/^(.+)?\!.+$/){ $1 }

      isPart = false
      @core.channels[channel][:modes].each { |mode, user|
        part channel, @config["reply"] if user == poster
        isPart = true if user == poster
      }
      
      message = "おまえが死ね"
			notice channel, message unless isPart
		end
	end
end
