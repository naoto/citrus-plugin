require 'yaml'

class WordCount < Citrus::Plugin

  def initialize(*args)
    super
    @word_file = "word_count.yaml"
    if File.exists?(@word_file)
      @data = YAML.load_file(@word_file)
    else
      @data = {}
    end
  end

    def on_privmsg(prefix, channel, message)
        @config["replies"].each do |r|
            if message =~ /(#{r["words"]})/ &&
               (!r["channels"] || r["channels"].include?(channel))
        @data[channel] = {} unless @data[channel]
        @data["date"] = Date.today.to_s unless @data["date"]
        if @data["date"] != Date.today.to_s
          @data = {}
          @data["date"] = Date.today.to_s
          @data[channel] = {}
        end
        user = ""
        if prefix =~ /!~(.+?)@/
          user = $1
        end
        count = @data[channel][user].to_i || 0
        count += 1
                notice(channel, "もう#{user}のその発言#{count}回目だよ") if count > 3

        @data[channel][user] = count
        f = File.open(@word_file,'w+')
        f.puts @data.to_yaml
        f.close
            end
        end
    end
end

