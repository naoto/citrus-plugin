require 'kconv'
require 'yaml'
class Naruto < Citrus::Plugin
	def on_privmsg(prefix, channel, message)
    
    if message =~ /(#{@config["words"]})/ &&
       (!@config["channels"] || @config["channels"].include?(channel))

      nouser = []
      users = Hash.new()
      postflg = false
      @core.channels[channel][:modes].each { |mode, user|
          users[user] = true 
      }
      @core.channels[channel][:users].each { |user|
        nouser << user if users[user].nil?
        if nouser.length == 3
          post "mode #{channel} +ooo #{nouser.join(" ")}"
          nouser.clear
          postflg = true
        end
      }

      post "mode #{channel} +ooo #{nouser.join(" ")}" unless nouser.empty?
      msg = (!postflg && nouser.empty?) ? @config["unreply"] : @config["reply"]
      notice channel, msg

    end

	end

end
