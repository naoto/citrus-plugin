
require 'rubygems'
require 'open-uri'
require 'hpricot'

class AmazonPrice < Citrus::Plugin
	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		case message
		when /(http:\/\/www\.amazon\.co\.jp\/.+)/
			notice(channel, get_price(Regexp.last_match[1]))
		end
	end

	private
	def get_price(uri)
		begin
			doc = Hpricot(open(uri).read)
			doc.at('.price').inner_text.sub(/([^0-9]+)/, '\\')
		rescue
			return nil
		end
	end
end

