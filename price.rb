require 'open-uri'
require 'hpricot'
require 'kconv'
require 'uri'

class Price < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
    if /#{@config["prefix"]}/ =~ message
      item = $1.tosjis.split(/\s/)
      uri = URI.escape("http://kakaku.com/search_results/#{item.join(" ")}/?act=Suggest")
      puts uri
      item_uri = Hpricot(open(uri)).at('a.title').attributes['href']

      html = Hpricot(open(item_uri))
      title = html.at('div.itmBoxIn/h2').inner_text.toutf8
      price = html.at('span#minPrice/a').inner_text
      notice(channel, "[#{title}] #{price} #{URI.short_uri(item_uri, "tiny")}")
		end

  rescue
    notice channel, "そんなのない"
	end
end

