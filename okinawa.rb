
require "yaml"

class Okinawa < Citrus::Plugin

	def initialize(config, chokan)
		super
    unless File.exist?("plugins/#{@config["data"]}")
		@datafile = @config["data"]
      puts "no conf"
    end
    @data = YAML.load(open("plugins/#{@config["data"]}"))
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		return unless @channels.nil? || @channels.include?(channel)
    @data.each { |str, infomation|
      if /#{str}(教|おし)えて/ =~ message
        @data = YAML.load(open("plugins/#{@config["data"]}"))
        notice(channel, @data[str])
      end
    }
	end
end
