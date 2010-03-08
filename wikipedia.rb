require 'rubygems'
require 'uri'
require 'net/http'
require 'hpricot'

class Wikipedia < Citrus::Plugin
	def initialize(*args)
		super
		@prefix = @config['prefix'] || '\? *?'
		@keyword
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)

		case message
		when /^[\s]{0,}(.+)#{@prefix}$/i
			parse(Regexp.last_match[1].gsub(/\s/,"_")).each {|m| notice(channel, m)}
		end
	end

	private
	def parse(keyword)
        address = URI.escape("http://ja.wikipedia.org/wiki/#{keyword}")
      begin
        html = Hpricot(open(address))
      rescue
        html, address = search(keyword)
      end
			begin
        m = html.search("p").first.inner_text[0..300]
        m << "\n"
        open("http://tinyurl.com/api-create.php?url=#{address}") do |f|
          m << f.read()
        end
			rescue
				'べ、別にあんたのために調べた訳じゃないんだからね！'
			end
	end

  private
  def search(keyword)
    begin
      shtml = Hpricot(open(URI.escape("http://ja.wikipedia.org/w/index.php?search=#{keyword}")))
      url = shtml.search("ul.mw-search-results").search("a").first.attributes['href']
      address = "http://ja.wikipedia.org#{url}"
      html = Hpricot(open(address))
      [html,address]
    rescue
      [nil,nil]
    end
  end
end

tests do
	describe Wikipedia do
		before :all do
			@core   = DummyCore.new({})
			@socket = @core.socket
			@prefix = Net::IRC::Prefix.new("foo!foo@localhsot")

			@plugin = Wikipedia.new(@core, { "Wikipedia" => {
			} })
		end

		it "should reply correctly" do
#					@socket.clear
#					@plugin.on_privmsg(@prefix, "#test", "foo")
#					@socket.pop.to_s.should == "NOTICE #test :Nice boat.\r\n"
		end
	end

end

