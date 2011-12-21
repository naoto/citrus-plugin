require "rubygems"
require "nokogiri"
require "open-uri"

class Dictionary < Citrus::Plugin

  def initialize(*args)
    super
    @code = {"e" => "en", "j" => "ja", "c" => "zh-CN", "k" => "ko", "f" => "fr", "a" => "ar"}
  end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)

		if /^(e|j)2{0,}(j|e)\s(.+)$/ =~ message
	    j = conv($3, $1, $2)
		  if j.empty?
				notice(channel, "スペルミス？")
			else
				notice(channel, j)
			end
    end
  end

	private
	def conv(e, to, from)
		result = ""
		uri = URI("http://www.google.com/translate_t?langpair=#{@code[to]}%7C#{@code[from]}&text=#{URI::escape(e)}")
	  doc = Nokogiri::HTML(open(uri))

		doc.search("span#result_box/span").each do |e|
	  	result << e.inner_text
	  end
		result
  end

end
