
class Tsukkomi < Citrus::Plugin
  
	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
    words = []
    parse = MeCab::Tagger.new.parse(message)
    parse.split(/\n/).each { |word|
      if word =~ /.+,(.+?),.+?,.+$/
        kana = $1 || ""
        if kana.split(//s).length > 2
          if words.include?(kana) || words.include?(kana.gsub(/ッ/,"") )
            notice channel, "さむい"
            break
          else
            words << kana.gsub(/ッ/,"")
          end
        end
      end
    }
	end

end

