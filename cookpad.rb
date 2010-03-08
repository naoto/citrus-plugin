require 'kconv'
require 'open-uri'
require 'nokogiri'

class Cookpad < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
		if message =~ /(#{@config["words"]})/ &&
	    (!@config["channels"] || @config["channels"].include?(channel))

      title, resipi,uri = resipiSearch($2)
      msg = resipi.empty? ? "そんなものはない" : "材料:#{resipi}"

			notice channel, title unless title.nil?
      notice channel, msg
      notice channel, uri unless uri.nil?
		end
	end

  private
  def resipiSearch(menu)
    baseuri = "http://cookpad.com"

    html = Nokogiri::HTML(open(URI.escape("#{baseuri}/レシピ/#{menu}")))
    elem = html.search("a.recipe-title").sort_by{rand}[0]
    
    resipi = []
    title = ""
    unless elem.nil?
      href = elem['href']
      rhtml = Nokogiri::HTML(open(href))
      rhtml.search("td.ingredient_row/span").each { |a|
        resipi << a.inner_text.gsub(/\s/,"")
      }
      title = rhtml.at("h1.recipe-title").inner_html.gsub(/\s/,"")
    end

    return [title, resipi.join("/"), href]

  end
end
