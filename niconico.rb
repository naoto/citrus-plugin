
require 'net/http'
require 'net/https'
require 'rubygems'
require 'cgi'
require 'uri'

class Niconico < Citrus::Plugin
	def initialize(*args)
		super
		@prefix = @config['prefix'] || /((s|v|n)m\d+)/
		@number = @config['number'].nil? ? 3 : @config['number'].to_i
    @id = @config['user']
    @pass = @config['pass']
    @path = @config['path']
	end

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
		case message
		when /#{@prefix}/
			result = download(Regexp.last_match[1])
		end
	end

	private
	def download (videoId)
     title = getNicoTitle(videoId)
     https = Net::HTTP.new('secure.nicovideo.jp',443)
     https.use_ssl = true
     https.verify_mode = OpenSSL::SSL::VERIFY_NONE
     https.start { |access|
       respons = access.post("/secure/login?site=niconico","next_url&mail=#{@id}&password=#{@pass}")
       cookie1 = respons['Set-Cookie']
       cookies = cookie1.scan(/user_session=user_session_[\w]+/)
       Net::HTTP.start('www.nicovideo.jp'){ |nico|
         videoId.each { |id|
           respons = nico.get("/watch/#{id}","Cookie"=>cookies[0])
           cookie2 = respons['Set-Cookie'].split(';')[0]
           respons2 = nico.get("/api/getflv?v=#{id}","Cookie"=>cookies[0])
           api_res = CGI.unescape(respons2.body)
           thread_id = api_res.scan(/thread_id=\d+/)
           api_res.scan(/url=http:\/\/(.*)(\/smile\?(v|m|s)+=[\d\.]+)/)
           Net::HTTP.start($1){ |flv|
             video = flv.get($2,'Cookie'=>cookie2)
             @title.gsub!(/\//,'')
             File.open("#{@path}#{id}.flv",'wb') do |f|
               f.write(video.body)
             end
           }
         }
       }
    }
	end

  private
  def getNicoTitle(videoId)
     agent = WWW::Mechanize.new
     agent.max_history = 1
     agent.user_agent_alias = 'Windows IE 6'
     @title = (agent.get("http://www.nicovideo.jp/watch/#{videoId}")/"/html/head/title").inner_text
     @title.gsub!("‐ニコニコ動画(秋)","")
     @title.gsub!(/[\t| |　]/,"-")
     @title.gsub!(/[［|］|]/,"")
     return @title
  end


end

