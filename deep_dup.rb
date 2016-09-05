# deep_dup from http://stackoverflow.com/questions/2579879/duplicating-a-ruby-array-of-strings
# deep_dup is slower than forming an empty array of same size and map dup them
# reason being that fixnum (ALL NUMERIC VALUES) cannot be duplicated
# location:
# require 'C:/Users/J Wong/Documents/ruby/deep_dup.rb'


class Array
  def deep_dup
    map {|x| x.deep_dup}
  end
end

class Object
  def deep_dup
    dup
  end
end

class Numeric
  # We need this because number.dup throws an exception
  # We also need the same definition for Symbol, TrueClass and FalseClass
  def deep_dup
    self
  end
end

#def dup_array(old_array)
#	data_n = Array.new(old_array.size)
#	data_n = old_array.map do |e| e end
#	return data_n
#end	
