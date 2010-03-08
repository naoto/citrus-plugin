require 'rubygems'
require 'MeCab'
require 'yaml'
require 'kconv'
$KCODE = 'u'

class Atom < Citrus::Plugin
    
  def initialize(*args)
    super
    @customWord = YAML.load_file('plugins/atom.yaml')
    custom_word_rep
  end

	def on_privmsg(prefix, channel, message)
		@config["replies"].each do |r|
			if message =~ /(#{r["words"]})/ &&
			   (!r["channels"] || r["channels"].include?(channel))
        
        syukugaword = customizer($2)

				notice channel, syukugaword
			end
		end
	end
  
  def preprocess(words)
    
    @customWord.each{ |pattern, replise|
       words.gsub!(/#{pattern}/,replise) 
    }
  end

  def custom_word_rep

    re = []
    @customWord.each { |pat, rep|
      re.push rep
    }

    @reexception = re.join("|")
  end

  def customizer(str)

    preprocess str
    ret = "" 
    strary = str.split(/(#{@reexception})/).each { |s|
      if s =~ /(#{@reexception})/
        ret << s
        next
      end
      
      if s !~ /\S/
        ret << s
        next
      end
      
      nextflg = false
      parse = MeCab::Tagger.new.parse(s)
      parsea = parse.split(/\n/)
      parsea.each_with_index { |word, index|
        puts word
        word.gsub(/^(.+?)[\t|\s]+(.+?),.+,(.+),.+$/){
          string = $1
          yomi = $3
          type = $2
          if yomi == '*'
             yomi = string
          end
          if nextflg
            nextflg = false
            next
          end

          if type == '動詞' && parsea.size > index + 1
            parsea[(index.to_i + 1)].gsub(/^(.+?)[\t|\s]+(.+?),.+,(.+),.+$/){
              next_string = $1
              next_yomi = $3
              next_type = $2
              
              if next_type == '助動詞'
                yomi << next_yomi
                nextflg = true
              end
            }
          end
          
          if type =~ /副詞|助動詞|形容詞|接続詞|助詞/ && string =~ /^[ぁ-ん]+$/
            ret << string
          elsif yomi
            ret << atomaizer(yomi) || string
          else
            ret << string
          end
        }
      }
    }
    return ret
  end

  def atomaizer (yomi)
    yomi.gsub!(/ー+/,"ー") 
    small_word = "ャュョッー"
    word_length = yomi.to_s.split(//).size

    sm =  yomi.scan %r{[#{small_word.toutf8}]}
    length = word_length - sm.length

    if length == 3 && yomi.gsub!(/ッ/,"ツ")
      length = 4
    end

    done = 0

    if length == 2
      tmp = apply_shisu_rule(yomi)
      if tmp
        yomi = tmp
        done = 1
      end
    end

    if length == 3
      tmp = apply_waiha_rule(yomi)
      if tmp
        yomi = tmp
        done = 1
      end
    end

    if length == 4
      tmp = apply_kuribitsu_rule(yomi)
      if tmp
        yomi = tmp
        done = 1
      end
    end

    if !done
      yomi.gsub!(/(.(?:ー+)?)$/,"#{$1}#{yomi}")
    end

    yomi.gsub!(/ッ$/,"ツ")

    return yomi
  end

  def apply_shisu_rule(yomi)
    return yomi if yomi.gsub(/^(.+?)(.[ー]{0,})$/){
      a, b = $1, $2
      a.gsub!(/ー/,"")
      b.gsub!(/ー/,"")
      yomi = "#{b}ー#{a}ー"
    }
  end

  def apply_waiha_rule(yomi)
    if yomi =~ /(.)([^ンー].)/
      yomi = "#{$2}#{$1}ー"
    end
    return yomi
  end

  def apply_kuribitsu_rule(yomi)
    if yomi =~ /(.+?)([^ンー].)$/
      yomi = "#{$2}#{$1}"
    end
    return yomi
  end
end
