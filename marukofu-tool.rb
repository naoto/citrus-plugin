require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :database => "twit",
  :host => "localhost",
  :user => "root",
  :timeout => 5000
)

class Word < ActiveRecord::Base
end

class Tie < ActiveRecord::Base
end

class MarukofuTool


  def make

    array = []
    loop do
      @word = Word.find(:first, :conditions => ["id < ? and typed = ?", "#{(1..410000).to_a.shuffle.take(1)}", "名詞"], :order => 'rand()')
      @tie = Tie.find(:first, :conditions => ["first_id = ?",@word.id], :order => 'rand()')
      break if !@tie.nil? && !@tie.to_id.nil?
    end
    array << @word
    @word = Word.find(@tie.second_id)
    array << @word
    @word = Word.find(@tie.to_id)
    array << @word

    loop do
      @tie = Tie.find(:first, :conditions => ["first_id = ? and second_id = ? ", array.reverse[0].id, array.reverse[1].id], :order => 'rand()')
      break if @tie.nil? || @tie.to_id.nil?
      array << Word.find(@tie.to_id)
    end

    array.map!{ |m| m.spell }.join
  rescue
    "気安く呼ぶな"
  end

end
