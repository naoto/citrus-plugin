require 'open-uri'
require 'hpricot'

class TrainDisaster < Citrus::Plugin

	def on_privmsg(prefix, channel, message)
    return if !@config["channels"].nil? && !@config["channels"].include?(channel)		
    if /#{@config["prefix"]}/ =~ message
      html = Hpricot(open("http://transit.map.yahoo.co.jp/diainfo/area?area=3"))
      train = $1
      train_dis = []
      html.search(".list/a").each { |root|
        if /(#{train})/ =~ root.inner_text
           train_dis = disaster(root.attributes['href'])
           train_dis.each { |dis|
              notice(channel,dis)
           }

        end
      }
      notice(channel,"とまってないよ!")if train_dis.empty?
    elsif /(なに|何)が(止|とま)ってるの/ =~ message
      html = Hpricot(open("http://transit.map.yahoo.co.jp/diainfo/area?area=3"))
      train_dis = []
      html.search(".list/a").each { |root|
        train_dis << "#{root.inner_text} #{URI.short_uri("http://transit.map.yahoo.co.jp#{root.attributes['href']}")}"
      }
      notice(channel,train_dis.join("/"))
      notice(channel,"とまってないよ!")if train_dis.empty?
		end
  end

  def disaster(uri)
     html = Hpricot(open("http://transit.map.yahoo.co.jp#{uri}"))
     dis = []
     html.search("#info/dl/dd").each{ |div|
       dis << div.inner_text
     }
     return dis
  end
end

