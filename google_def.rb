
class GoogleDef < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
    if message =~ /#{@config["prefix"]}/
			   (!@config["channels"] || @config["channels"].include?(channel))

      test = Nokogiri::HTML(open(URI.escape("http://www.google.co.jp/search?q=define:#{$1}"))).at("ul[@class='std']/li").text
		  notice channel, test
		end
	end
end
