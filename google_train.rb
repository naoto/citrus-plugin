require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'kconv'

class GoogleTrain < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)		
    if /#{@config["prefix"]}/ =~ message

      station = $1
      line = $2

      getSchedule(station,line).each{ |n|
        notice channel,n
      }
    end
  end

  def getSchedule(station,line)

    hour = Time.now.strftime("%H")
    schedule_ary = []

    uri = URI.escape("http://maps.google.co.jp/maps/place?q=#{station}&line=#{line}")
    html = Nokogiri::HTML(Kconv.toutf8(open(uri).read))
    html.search(".pp-timetable-dir").each { |d|
      schedule_ary << d.at(".pp-timetable-headsign").text.gsub(/^(.+?方面).+$/,"\\1")
      d.search(".pp-timetable-hour-line").each { |t|

        htag = t.at(".pp-timetable-hour")
        h = htag.inner_text.gsub(":","") if !htag.nil?
        if h == hour
          schedule = "#{h}: "
          t.search(".pp-timetable-minute").each{ |ho|
            schedule << "#{ho.inner_text} "
          }

          schedule_ary <<  schedule
          break
        end
      }
   }
   schedule_ary << "そんな路線しらないなぁ" if schedule_ary.empty?
   return schedule_ary
  end
end

