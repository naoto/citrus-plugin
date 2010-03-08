# -*- coding: utf-8 -*-
require 'rubygems'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'uri'

class GoogleTransit < Citrus::Plugin
  def initialize(*args)
    super
  end

  def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)
    case message
    when /^(.+)から(.+)へのルート教えて$/x
      searchRoute($1,$2).each do |m|
        notice(channel, m)
        sleep 1
      end
    end
  end

  private
  def searchRoute(searchFrom, searchTo)
    from = URI.escape(searchFrom.toutf8)
    to   = URI.escape(searchTo.toutf8)
    query= "http://maps.google.co.jp/maps?f=q&source=s_q&hl=ja&geocode=&q=from%3A+#{from}+to%3A+#{to}"
    uri  = URI.parse(query)
    Net::HTTP.start(uri.host, uri.port) do |http|
      response = http.get(uri.request_uri)
      if response.code.to_i == 200 then
        begin
        document = Hpricot(response.body)
        from_st = document.at("#ddw_addr_area_0/#sxaddr/div.sa").inner_html.toutf8
        end_st  = document.at("#ddw_addr_area_1/#sxaddr/div.sa").inner_html.toutf8
        tr_cost = document.at("#transit_route_0").search('span.ts_routecost').inner_html.toutf8
        tr_time = document.at("#transit_route_0").search('span.ts_jtime').inner_html.toutf8
        messages = Array.new()
        messages << "#{from_st} -> #{end_st} #{tr_time} #{tr_cost}"
        document.search("#transit_route_0").each { |t|
          t.search("table.ts_step").each { |r|
            r.search("span.longline"){ |line|
              messages << "【#{line.inner_html.toutf8}】"
            }
            r.search("span.location").each { |station|
              messages << station.inner_html.toutf8
            }
          }
        }
        messages << URI.short_uri(query)
        rescue Exception
          messages = "おしえないよ！"
        end
      end
      return messages
    end
  end

end

