#!/usr/bin/env ruby

require "net/http"
require "net/https"
require "net/http/paranoid"
require "image_size" # gem install imagesize
require "timeout"

class Default < Handler
	MAX_REDIRECT = 10
	HEADERS      = {
		"User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12",
		"Accept"     => "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
	}

	def process(uri)
		timeout(5) do
			http(uri)
		end
	end

	def http(uri, headers=HEADERS, limit=MAX_REDIRECT)
		return "Redirect loop?: last:#{uri}" if limit <= 0
		paranoid = Net::HTTP::Paranoid.new
		paranoid.whitelist = @parent.config["whitelist"]
		paranoid.blacklist = @parent.config["blacklist"]

		log uri
		ret = ''
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = (uri.scheme == "https")
		paranoid.wrap(http).start do |http|
			r = http.head(uri.request_uri, headers)
			log r.code.inspect
			case r
			when Net::HTTPOK # 200
				case r["Content-Type"]
				when /html/
					ret = html(http.get(uri.request_uri, headers.merge({
						"Range" => "0-5000"
					})))
				when /image\//
					ret = image(http.get(uri.request_uri, headers))
				else
					if r["Content-Length"]
						size = r["Content-Length"].to_i / 1024
						ret = "[#{r["Content-Type"]}] #{size}KB"
					else
						ret = "[#{r["Content-Type"]}]"
					end
				end
			when Net::HTTPUnauthorized # 401
				realm = r["WWW-Authenticate"][/Basic realm="([^"]+)"/, 1]
				auth  = (@parent.config["http_auth"] || []).find {|e| e["host"] == uri.host and e["realm"] == realm }
				if auth
					auth = "Basic " + ["#{auth["user"]}:#{auth["pass"]}"].pack("m")
					ret = http(uri, headers.update({'Authorization' => auth}), limit-1)
				else
					ret = realm
				end
			when Net::HTTPRedirection # 300 .. 399
				loc = URI(r["Location"])
				loc = uri + loc if loc.relative?
				ret = http(loc, headers, limit-1)
			else
				ret = "[#{r.code} #{r.message}]"
			end
		end

		ret
	end

	def image(res)
		size = res.body.length / 1024
		img = ImageSize.new(res.body)
		ret =  "#{img.get_type} Image, "
		ret << "#{img.get_width || "?"}x#{img.get_height || "?"} "
		ret << "#{size.to_i}KB"
	end

	def html(res)
		title = res.body[/<title.*?>(.*?)<\/title\s*>/imn, 1]
		title = "タイトル無し " if !title || title.empty?
		title = title.gsub(/\s+/, " ").gsub(/<.*?>/, "").to_u8
		title.gsub!(/&#(x)?([0-9a-f]+);/i) do |m|
			[$1 ? $2.hex : $2.to_i].pack("U")
		end
		if title.size > 70
			title = title[/.{0,60}/] + "..."
		end

		title = title.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/&amp;/, "&")

		"#{title} [#{res["Content-Type"]}]"
	end
end


tests do
end
