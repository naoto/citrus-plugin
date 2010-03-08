require 'nokogiri'
require 'open-uri'

class TwitterSearch < Citrus::Plugin
    def on_privmsg(prefix, channel, message)
      if message =~ /(#{@config["words"]})/ &&
          (!@config["channels"] || @config["channels"].include?(channel))

        words = $1 if message =~ /^tws\s(.+)$/
        search(words.split(/\s/)).each { |result|
          notice channel, result
          break if result == 3
        }
      end
    end

    private
    def search(words)
      result = []
      words.each { |word| word.gsub!(/(-)/,'"\\1"') if word =~ /^([^#])/ }
      url = "http://search.twitter.com/search.atom?q=#{words.join("+")}&lang=all"

      puts url

      html = Nokogiri::HTML(open(URI.escape(url)))
      html.search("entry").each{ |e|
        result << "@#{e.at('author/name').content.gsub(/\(.+$/,'')}: #{e.at('title').content} #{URI.short_uri(e.at("link")["href"])}"
        break if result.size > 2 
      }
      result << "しらない" if result.empty?
      return result
    end
end

