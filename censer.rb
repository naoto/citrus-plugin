require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'

class Censer < Citrus::Plugin
	def on_privmsg(prefix, channel, message)

    return if !@config["channels"].nil? && !@config["channels"].include?(channel)

		if message =~ /#{@config["prefix"]}/
        uri = URI.escape("http://www.google.co.jp/search?hl=ja&q=#{$1}+気温")
        html = Nokogiri::HTML(open(uri))
        temperature = html.at("div/div/b").content || "わかんない"
				notice channel, temperature
		end
	end
end
