require 'plugins/marukofu-tool.rb'

class Marukofu < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		if message =~ /#{@config["words"]}/ &&
		   (!@config["channels"] || @config["channels"].include?(channel))
      mf = MarukofuTool.new
      ret = mf.make
	  	notice channel, ret.gsub(/[「」【】『』:\/\/]/,"")
	  end
	end

end

