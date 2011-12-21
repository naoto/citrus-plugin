
require 'rubygems'
require 'open-uri'
require 'uri'
require 'nokogiri'
require 'kconv'

class AmazonSearch < Citrus::Plugin
	def description
		<<-DESCRIPTION.gsub(/^\s+/, '')
			このプラグインは Google の API を利用しておらず、真っ黒です。
			絶対に利用しないでください。
			<http://www.google.com/accounts/TOS>
		DESCRIPTION
	end

  def initialize(*args)
    super
    @prefix = @config['prefix'] || 'as'
    @number = @config['number'] || 1
    @limit  = @config['limit']  || 10
    @affiliateid = @config['id'] || ""
  end

  def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
    case message
    when /
      ^
      (as|)(\s+|)(.+?)(を|)(うっかり|)
      $
    /x
      return nil if String($1).blank? && String($5).blank?
      words  = $3
      number = 3
      result = search(words, number)
      notice(channel, "そんなのないよ") if result.empty?
      result.each { |line|
          notice(channel, line)
      }

    end
  end

  private
  def search (string, shu=nil)

    result   = []
    keywords = string.split(/\s+/).collect{ |item| URI.escape(item, /[^-.!~*'()\w]/n) }.join('+')
    number   = shu.nil? || shu.zero? ? @number : shu <= @limit ? shu : @limit

    uri      = URI.parse("http://www.google.co.jp/search?q=#{keywords}+site:amazon.co.jp&ie=utf-8&oe=utf-8&lr=lang_ja&num=#{number}")
    document = Nokogiri::HTML(Kconv.kconv(open(uri).read,Kconv::UTF8,Kconv::ASCII))
    document.search("h3.r").each { |node|
      break if result.size >= number

      price = get_price(node.at('a')['href'])
      link = node.at('a')['href']
      if /(\/dp\/[\w]+)/ =~ link
        link.gsub!(/amazon.co.jp\/.+(\/dp\/[\w]+)/, "amazon.co.jp\\1")
        link.gsub!('/dp/', '/o/ASIN/')
        link.concat("/#{@affiliateid}/ref=nosim")
      elsif /\?/ =~ link
        link.concat("&tag=#{@affiliateid}")
      else
        link.concat("/#{@affiliateid}")
      end
      result << "[#{node.inner_text().toutf8}] \\#{price} #{URI.short_uri(link)}"
    }

    result
  end

  def get_price(uri)
    begin
      doc = Nokogiri(open(uri))
      /([0-9,]+)/ =~ doc.at('.priceLarge').inner_text()
      return $1
    rescue
      return nil
    end
  end
end
