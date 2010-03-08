require 'open-uri'
require 'nokogiri'

class Twitter < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		
    if /#{@config["prefix"]}/ =~ message
      user = $2
      cnt = $3.to_i || 0
      url = "http://twitter.com/#{user}"
      if cnt > 19
        page = ((cnt + 1) / 20).ceil + 1
        url << "?page=#{page}"
        cnt = cnt % 20
      end

      html = Nokogiri::HTML(open(url))
      twit = nil
      date = nil
      html.search(".entry-content").each_with_index{ |t,i|
        twit = t if i == cnt
      }
      html.search(".entry-meta/a/span").each_with_index{ |d,i|
        date = d if i == cnt
      }
      if !twit.nil?
        twit = "@#{user}: #{twit.content} (#{date.content})"
      else
        twit = html.search("h1.logged-out").first
        if twit.nil?
          twit = "だれそれ"
        else
          twit = twit.inner_text
        end
      end
      notice(channel, twit)
		end

  rescue
    notice(channel,"だれそれ")
	end
end

