require 'net/http'
require 'hpricot'
require 'htmlentities'

class TwitterId < Citrus::Plugin
	def initialize(*args)
		super
		@prefix = @config['prefix'] || 't '
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		case message
		when /^#{@prefix}(.+)$/i
			notice(channel, twitterer(Regexp.last_match[1]))
		end
	end

	private
	def twitterer(user)
		return "http://twitter.com/#{user}" if user == 'home'

		Net::HTTP.start('twitter.com', 80) do |http|
			begin
				r = Net::HTTP::Get.new("/users/show/#{user}.xml")
				r.basic_auth @config['screen_name'], @config['password']
				response = http.request(r)
				log response.code.inspect

				case response.code.to_i
				when 400
					return "くぁwせdrftgyふじこlp； http://twitter.com/#{user}"
				when 401
					return "見せなさいよ！ いるのは分かってるんだからねっ！ http://twitter.com/#{user}"
				when 404
					return 'いないわよ？'
				end

				xml = Hpricot(response.body)
				html = HTMLEntities.new
				name      = html.decode((xml/'name').inner_html)
				location  = html.decode((xml/'location').inner_html)
				uri       = (xml/'url').inner_html
				following = (xml/'friends_count').inner_html
				followers = (xml/'followers_count').inner_html
				favorites = (xml/'favourites_count').inner_html
				favotter  = favotter(user)
				updates   = (xml/'statuses_count').inner_html
				follow_ratio   = '%.2f' % (followers.to_f / following.to_f) || '-'
				favotter_ratio = '%.2f' % (favotter.to_f / updates.to_f * 100)  || '-'

				"#{name}@#{location} [#{format(following)}/#{format(followers)}(#{follow_ratio}), #{format(favorites)}favs, #{format(updates)}updates/#{format(favotter)}favotter(#{favotter_ratio}%)] #{uri} http://twitter.com/#{user} http://favotter.matope.com/user.php?user=#{user}"
			rescue Exception => e
				log e
				"http://twitter.com/#{user}"
			end
		end
	end

	def favotter(user)
		Net::HTTP.start('favotter.matope.com', 80) do |http|
			response = http.get("/user.php?user=#{user}")
			doc = Hpricot(response.body)

			/\((\d+)\)/.match(doc.at('title').inner_html).to_a[1]
		end
	end

	def format(i)
		i.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,').sub(/\.0+$/, '')
	end
end

tests do
	describe TwitterId do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhsot")

			@plugin = TwitterId.new(@core, { "TwitterId" => {
			} })
		end

		it "should reply correctly" do
#					@socket.clear
#					@plugin.on_privmsg(@prefix, "#test", "foo")
#					@socket.pop.to_s.should == "NOTICE #test :Nice boat.\r\n"
		end
	end

end

