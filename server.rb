
class Server < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
		if message =~ /#{@config['prefix']}/
      if $1 == "HP"
        df = `df`.split(/\n/)
        total = 0
        df.each { |l|
          if l =~ /([0-9]+)[\s\t]+[0-9]+%.+?$/
             total = total + Integer($1)
          end
        }
        ringo = total / 1000000
			  notice channel, "ミカン#{ringo}個ぐらい"
      end
		end
	end
end

