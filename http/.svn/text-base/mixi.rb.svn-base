#!/usr/bin/env ruby

require "net/http"
require "net/https"
require "net/http/paranoid"
require "image_size" # gem install imagesize
require "timeout"

class Mixi < Default
	HEADERS = {
		"User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12",
		"Accept"     => "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
	}

	def initialize(parent)
		super
		parent.config['handlers'].each do |c|
			next if c['Mixi'].nil?
			@email    = c['Mixi']['user']
			@password = c['Mixi']['pass']
		end
	end

	def process(uri)
		timeout(5) do
			mixi(uri)
		end
	end

	def mixi(uri, headers=HEADERS)
		return unless uri.host == 'mixi.jp'
		cookie = {}
		login_uri = URI("http://mixi.jp/login.pl")
		Net::HTTP.start(login_uri.host, login_uri.port) do |http|
			data = {
				"next_url" => "/home.pl",
				"email"    => @email,
				"password" => @password,
				"sticky"   => ""
			}
			data = data.collect {|k,v| "#{k}=#{URI.escape(v)}" }.join("&")
			res = http.post(login_uri.request_uri, data, HEADERS)
			if res.key?("set-cookie")
				res["set-cookie"].split(/\s*,\s*/).each do |c|
					k, v =c.sub(/;.*/, "").split(/=/)
					cookie[k] = v
				end
			else
				raise LoginError, "Invalid e-mail or password"
			end
		end
		http(uri, {
			"Cookie" => cookie.collect {|c| c.join("=") }.join(";")
		})
	end
end

tests do
end
