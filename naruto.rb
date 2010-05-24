require 'kconv'

class Naruto < Citrus::Plugin

  def on_privmsg(prefix, channel, message)
    
    if message =~ /(#{@config["words"]})/ &&
       (!@config["channels"] || @config["channels"].include?(channel))

      users = []
      @core.channels[channel][:modes].each { |mode, user|
        users << user 
      }

      diff = @core.channels[channel][:users] - users
      diff.each_slice(3) { |user|
        post "mode #{channel} +ooo #{user.join(" ")}"
      }

      msg = @config["reply"]
      notice channel, msg

    end
  end
end
