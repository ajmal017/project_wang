require "inline"

class ArrayMath
    inline :C do |builder|
        builder.c "
            VALUE count_p(VALUE arr, VALUE count_v){

                int size = RARRAY_LEN(arr);
                VALUE *c_arr = RARRAY_PTR(arr);
                int i;
                int counting = 0;
                for (i=0; i<size; i++) {
                    if (NUM2DBL(c_arr[i])>=NUM2DBL(count_v)){
                        counting += 1;
                    }    
                }
            return( rb_float_new(counting) );
        }"
    end
    inline :C do |builder|
        builder.c "
            VALUE count_n(VALUE arr, VALUE count_v){

                int size = RARRAY_LEN(arr);
                VALUE *c_arr = RARRAY_PTR(arr);
                int i;
                int counting = 0;
                for (i=0; i<size; i++) {
                    if (NUM2DBL(c_arr[i])<=NUM2DBL(count_v)){
                        counting += 1;
                    }    
                }
            return( rb_float_new(counting) );
        }"
    end
end


class Array
inline do |builder|
  builder.c <<-EOC
        static VALUE 
        rb_ary_sum(){
            double result = 0.0;
            long i, len     = RARRAY_LEN(self);
            VALUE *c_arr    = RARRAY_PTR(self);

    for(i=0; i<len; i++) {
      result += NUM2DBL(c_arr[i]);
    }

            return rb_float_new(result);
        }
    EOC

    builder.c <<-EOC
        static VALUE 
        rb_ary_avg(){
            double result = 0.0;
            double sum, len = RARRAY_LEN(self);

            sum = NUM2DBL( rb_ary_sum(self) );

            result =  sum/len;
            return rb_float_new(result);
        }           

    EOC
    end

def sum
    rb_ary_sum
end

def avg 
    rb_ary_avg
end
end
=begin
require 'benchmark'
iterations = 1000000
def bench(name, &block)
  time = Benchmark.realtime do
    yield block
  end
  puts "#{name}: #{time}"
end 
bench :sum_in_c do
    iterations.times do
        pie = ArrayMath.new.sum(array_1)
    end
end
bench :sum_inject do
    iterations.times do
        pie = array_1.inject(:+)
    end
end


i, summm=0, 0.0
while i<array_1.count
    summm += array_1[i]
    i+=1
end
p ArrayMath.new.sum(df2_2)
p df2_2.inject(:+)
p summm
# ArrayMath.new.sum(df2_2) == summm == true

=end

=begin
    #failed tests, ruby is faster
            VALUE ccount(VALUE arr){
                int size = RARRAY_LEN(arr);
            return(INT2NUM(size));
    #other sum is faster
    inline :C do |builder|
   builder.c "
        VALUE sum(VALUE arr){

            int size = RARRAY_LEN(arr);
            VALUE *c_arr = RARRAY_PTR(arr);

            int i;
            float sum = 0.0;
            for (i=0; i<size; i++)
            {
                sum += NUM2DBL(c_arr[i]);
                
            }

            return( rb_float_new(sum) );
        }"
   end
=end