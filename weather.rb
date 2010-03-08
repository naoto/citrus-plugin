# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'uri'
require 'kconv'
class Weather < Citrus::Plugin
  def initialize(*args)
    super
    @prefix = @config['prefix'] || 'の天気'
    @keyword
  end

  def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)

    case message
    when /^[\s]{0,}#{@prefix}/i
      day = %w(今日 明日 明後日 明々後日)
      weather,censer = getWeather(Regexp.last_match[1])
      weather.each_with_index do |m,i|
        notice (channel, "#{day[i]}#{m} (#{censer[i]})")
      end
    end
  end

  private
  def getWeather(city)
    
    h = Nokogiri::HTML(Kconv.toutf8(open(URI.escape("http://www.google.co.jp/search?q=週間天気+#{city}")).read))

    weather = []
    h.search("img").each{ |i|
      weather << "の天気は#{i["title"]}" unless i["title"].nil?
    }
    

    censer = []
    h.search("table.ts.std div nobr").each{ |n|
      censer << n.inner_text.gsub(/°C/,"度") unless n.inner_text.blank?
    }

    [weather,censer]
  end


end







