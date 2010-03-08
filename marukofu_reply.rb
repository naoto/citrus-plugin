require 'plugins/marukofu-tool.rb'

class MarukofuReply < Citrus::Plugin
  
	def on_privmsg(prefix, channel, message)
    @config["replies"].each do |r|
		  if message =~ /^#{r["words"]}/ &&
		     (!@config["channels"] || @config["channels"].include?(channel))
        rep_word = r["reply"] || r["words"]
        mf = MarukofuTool.new
        word = mf.message(rep_word)
        ret = mf.search(word)
	  	  notice channel, ret[0].gsub(/[「」【】『』:\/\/\[\]:punct:]/,"")
	    end
    end
	end

end

