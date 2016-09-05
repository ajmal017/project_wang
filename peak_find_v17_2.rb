#new peak find for V17
# V17_2 is to add the number of candles between each peak instead of relying on timestamp which is inaccurate for weekends

require "inline"
require 'gsl'
require 'fastcsv'
require 'csv'

require_loc = "/home/jwong/Documents/ruby"
require require_loc + "/deep_dup.rb"
require require_loc + "/arraymath.rb"

# C extension documentation http://www.eqqon.com/index.php/Ruby_C_Extension_API_Documentation_(Ruby_1.8)
# http://opensource.apple.com//source/ruby/ruby-14/ruby/array.c


class Peak_evaluate
attr_accessor :width,:minor_width,:second_dir, :prev_peak_t, :prev_peak, :prev_base_t, :prev_base, :prev_slope, :x_ax_2, :current_time


	def initialize(width, minor_width, second_dir =4)
		self.width = width
		self.minor_width = minor_width
		self.second_dir = second_dir 	#to calculate the second derivative
		self.prev_peak_t =[]
		self.prev_peak=[]
		self.prev_base_t = []
		self.prev_base = []
		self.prev_slope=[]
		
		self.current_time =0
		self.x_ax_2 = x_index(second_dir)
		
		#outcome -> [[[peak_time], [peak_value]], [[base_time], [base_value]], last_time]
	end
	
	def peak_find_slope(dataset_time, dataset_val)
		# find last timestamp

		@@width=self.width
		@@minor_width=self.minor_width
		@@second_dir=self.second_dir
		@@prev_peak_t=self.prev_peak_t
		@@prev_peak=self.prev_peak
		@@prev_base_t=self.prev_base_t
		@@prev_base=self.prev_base
		@@prev_slope=self.prev_slope
		@@x_ax_2 = self.x_ax_2
		@@current_time = self.current_time

		@@prev_peak_t.shift if @@prev_peak_t.count >= 20
		@@prev_peak.shift if @@prev_peak.count >= 20
		@@prev_base_t.shift if @@prev_base_t.count >= 20
		@@prev_base.shift if @@prev_base.count >= 20


		empty_array = Array.new()
		new_peeking = Peak.new()
		outcome = new_peeking.find_peak_c(dataset_time, dataset_val, @@prev_peak_t, @@prev_peak, @@prev_base_t, @@prev_base, empty_array, empty_array, @@current_time, @@width, @@minor_width)
		
		self.prev_peak_t = outcome[0][0].deep_dup
		self.prev_peak=outcome[0][1].deep_dup
		self.prev_base_t = outcome[1][0].deep_dup
		self.prev_base = outcome[1][1].deep_dup
		self.current_time =outcome[2].deep_dup

		@@prev_peak_t=outcome[0][0]
		@@prev_peak=outcome[0][1]
		@@prev_base_t=outcome[1][0]
		@@prev_base=outcome[1][1]

		@@dataset_count=dataset_time.count
		#find slope for peak/base to current, 2nd peak/base to current


		if @@prev_peak.count>=1
			ii_peak = @@dataset_count-1	
			most_recent_pe = @@prev_peak_t[-1]
			ii_peak-=1 until ii_peak==0 || dataset_time[ii_peak] <= most_recent_pe
			lag_v = @@dataset_count+1-ii_peak
			peak_slope_1 = linear_reg(dataset_val, lag_v)
		else
			peak_slope_1 = [0,0,0,0,0,0,0,0,0]
		end
		if @@prev_peak.count>=2	
			most_recent_pe = @@prev_peak_t[-2]
			ii_peak-=1 until ii_peak==0 || dataset_time[ii_peak] <= most_recent_pe
			lag_v = @@dataset_count+1-ii_peak
			peak_slope_2 = linear_reg(dataset_val, lag_v)
		else
			peak_slope_2 = [0,0,0,0,0,0,0,0,0]
		end
		
		if @@prev_base.count>=1
			ii_base = @@dataset_count-1
			most_recent_ba = @@prev_base_t[-1]
			ii_base-=1 until ii_base==0 || dataset_time[ii_base] <= most_recent_ba
			lag_v = @@dataset_count+1-ii_base
			base_slope_1 = linear_reg(dataset_val, lag_v)
		else
			base_slope_1 = [0,0,0,0,0,0,0,0,0]
		end
		if @@prev_base.count>=2	
			most_recent_ba = @@prev_base_t[-2]
			ii_base-=1 until ii_base==0 || dataset_time[ii_base] <= most_recent_ba
			lag_v = @@dataset_count+1-ii_base
			base_slope_2 = linear_reg(dataset_val, lag_v)
		else
			base_slope_2 = [0,0,0,0,0,0,0,0,0]
		end
		
		
		return peak_slope_1, peak_slope_2, base_slope_1, base_slope_2
		
	end	
		
	def linear_reg(dataset, lag_v)
	
		json,data_2=[],[]
		x_ind = x_index(lag_v)
		
		do_here=@@dataset_count-(@@second_dir+1) # just need exactly @@second_dir total values 	
		i=do_here 
			#for testing, pleasse remove after it's correct
			if x_ind.count != dataset[i-lag_v..i].count
				10.times{puts" x_ind != DATASET"}
				
			end	
			
		while i<@@dataset_count
			intercept, regression_slope, cov00, cov01, cov11, chisq = linearregression(x_ind, dataset[i-lag_v..i])
			intercept_diff = intercept-dataset[i]
			errors=chisq #subject to change between cov00, cov01, cov11
			estimated_value = regression_slope/cov00  #need to check values are doable
			est_diff_bid_slope = regression_slope/cov01
			est_diff_ask_slope = regression_slope/cov11
			json.push([regression_slope,errors,intercept_diff,est_diff_bid_slope,est_diff_ask_slope,0.0,0.0,0.0,lag_v])				
			data_2.push(regression_slope)
			i+=1
		end
				


		i2=data_2.count-1 
		intercept2, regression_slope2, cov00_2, cov01_2, cov11_2, chisq_2 = linearregression(@@x_ax_2, data_2[i2-@@second_dir..i2]) 
		json[-1][5] = regression_slope2
		json[-1][6]= chisq_2
		json[-1][7]= regression_slope2/cov00_2
		return_json_value = json[-1]
		
		return return_json_value

	end
		
	def x_index(value)
		x_axis=[]
		i=0
		while i<value+1
			x_axis.push(i)
			i+=1
		end
		return x_axis
	end	
		
		
	def linearregression(xs, ys)
  		x = GSL::Vector.alloc(xs)
  		y = GSL::Vector.alloc(ys)
  		intercept, slope, cov00, cov01, cov11, chisq, status = GSL::Fit::linear(x, y)
  		return intercept, slope, cov00, cov01, cov11, chisq
	end	
			
end



=begin
	:return[0]= peak arrays
	return[0][0] = peak_array_timestamp
	return[0][1] = peak_array_values
	:return[1] = base arrays
	return[1][0] = base_arrays_timestamp
	return[1][1] = base_arrays_values
	return [2] = recent time
	:return[3] = distance between peaks
	return[3][0] = distance between peaks and previous peak
	return[3][1] = diatance between peak and previous base
	: return[4] = distance between bases
	return[4][0] = distance between base and previous base
	return[4][1] = distance between base and previous peak

=end

class Peak
# select range of items in array http://stackoverflow.com/questions/3130232/selecting-a-range-of-items-inside-an-array-in-c-sharp
# ruby array manipulation C http://clalance.blogspot.my/2011/01/writing-ruby-extensions-in-c-part-9.html
# VALUE changes https://silverhammermba.github.io/emberb/c/#numeric  

     inline :C do |builder|
        builder.c "
        
           VALUE find_peak_c(VALUE timestamp_d, VALUE value_d, VALUE prev_peak_t, VALUE prev_peak_v, VALUE prev_base_t, VALUE prev_base_v, 
								VALUE prev_peak_ind_diff, VALUE prev_base_ind_diff ,VALUE recent_time, VALUE intvl, VALUE s_intvl){
			/* timestamp_d is data timestamp, value_d is for data value */
				int interval = NUM2INT(intvl);

				/*double cur_time = NUM2DBL(cur_t);*/
                int size = RARRAY_LEN(timestamp_d);
				int last_val = size-1;
				int max_size = size-interval;
				long peak_size = RARRAY_LEN(prev_peak_t);
				long base_size = RARRAY_LEN(prev_base_t);
                VALUE *c_time_d = RARRAY_PTR(timestamp_d);
				VALUE *c_val_d= RARRAY_PTR(value_d);
				VALUE *c_time_pre = RARRAY_PTR(prev_peak_t);
				VALUE *c_time_pre_base = RARRAY_PTR(prev_base_t);
	
                int ii=0;

				int i = 0;
				int timestamp_t = 0;
				int value_v = 1;
				
				int pre_ii, post_ii, loc, i_temp;
			
 				double pie = 0.0;

 				VALUE peak_array_t;
 				VALUE peak_array;
 				VALUE base_array_t;
 				VALUE base_array;
				VALUE peak_array_diff;
				VALUE base_array_diff;
				
 				VALUE full_array = rb_ary_new();

 				int s_dev = NUM2INT(s_intvl);
 				double cur_high, cur_low, sum_avg_val;
 				VALUE curr_high, curr_low;
 				double tot_s_dev = ((NUM2DBL(s_intvl)*2.0)+1.0);
 				int pre_s_dev, post_s_dev;
				
				int cur_ii_peak = last_val; 
				int cur_ii_base = last_val;
				int cur_diff_1, cur_diff_2;
				
 				/* find most recent value for peak and base */
 				if(peak_size>=1){
 					peak_array_t = rb_ary_dup(prev_peak_t);   
 					peak_array = rb_ary_dup(prev_peak_v); 
					peak_array_diff = rb_ary_dup(prev_peak_ind_diff);
					do { cur_ii_peak--; }while (cur_ii_peak >= 0 && c_time_d[cur_ii_peak]>=c_time_pre[peak_size-1]);
				}else{
					peak_array_t = rb_ary_new();
 					peak_array = rb_ary_new();
					peak_array_diff = rb_ary_new();
					cur_ii_peak=0;
				}
				if(base_size>=1){
					base_array_t = rb_ary_dup(prev_base_t);
 					base_array = rb_ary_dup(prev_base_v);
					base_array_diff = rb_ary_dup(prev_base_ind_diff);
					do { cur_ii_base--; }while (cur_ii_base >= 0 && c_time_d[cur_ii_base]>=c_time_pre_base[base_size-1]);
				}else{
					base_array_t = rb_ary_new();
 					base_array = rb_ary_new();
					base_array_diff = rb_ary_new();
					cur_ii_base=0;
				}
				
				/* finding most recent time */
				ii=size;
				do {ii--; }while( ii >= 0 && c_time_d[ii]>recent_time); 
				ii+=interval;

				if (ii>(max_size-1)){
					goto ending;  
				} /* if no changes in values, just return unchanged array */
				


				do {
					pre_ii = ii-interval;
					post_ii = ii+interval;
					if(pre_ii<0){
						post_ii -= pre_ii;
						ii -= pre_ii;
						pre_ii = 0;
					}
					
					if (post_ii>=size){
						goto ending;
					} /*if too close, then break*/
					
					/* get avg values-> sum values then divide by */
					sum_avg_val=0.0;
					pre_s_dev = ii-s_dev;
					post_s_dev = ii+s_dev+1;
					
					for (i_temp=pre_s_dev; i_temp<post_s_dev; i_temp++) {	
						sum_avg_val += NUM2DBL(c_val_d[i_temp]);   
					}
					sum_avg_val /= tot_s_dev;


						
					if ((sum_avg_val > NUM2DBL(c_val_d[pre_ii])) && (sum_avg_val > NUM2DBL(c_val_d[post_ii])))
					{
						curr_high = c_val_d[pre_ii];
						loc = 0;
						for (i=pre_ii; i<post_ii; i++) {
							if (c_val_d[i]>curr_high){
								curr_high = c_val_d[i];
								loc = i;
								/*cur_high = NUM2DBL(c_val_d[i]);*/
								
							}    
						}
						if (c_time_d[ii]>recent_time){
							cur_diff_1 = loc-cur_ii_peak;
							cur_diff_2 = loc-cur_ii_base;
							if (cur_diff_2>0){
								peak_size = RARRAY_LEN(peak_array);
								rb_ary_store(peak_array, peak_size, curr_high);
								rb_ary_store(peak_array_t, peak_size, c_time_d[loc]);
								rb_ary_store(peak_array_diff, peak_size, rb_ary_new3(2,INT2NUM(cur_diff_1),INT2NUM(cur_diff_2)));
								cur_ii_peak = loc;
								recent_time=c_time_d[ii];
							}
						}

					} else if ((sum_avg_val < NUM2DBL(c_val_d[pre_ii])) && (sum_avg_val < NUM2DBL(c_val_d[post_ii])))
					{
						curr_low=c_val_d[pre_ii];
						loc = 0;
						for (i=pre_ii; i<post_ii; i++) {
							if (c_val_d[i]<curr_low){
								curr_low = c_val_d[i];
								loc = i;
							}    
						}
						if (c_time_d[ii]>recent_time) {
							cur_diff_1 = loc-cur_ii_base;
							cur_diff_2 = loc-cur_ii_peak;
							if (cur_diff_2>0){
								base_size = RARRAY_LEN(base_array);
								rb_ary_store(base_array, base_size, curr_low);
								rb_ary_store(base_array_t, base_size, c_time_d[loc]);
								rb_ary_store(base_array_diff, base_size, rb_ary_new3(2,INT2NUM(cur_diff_1),INT2NUM(cur_diff_2)));
								cur_ii_base=loc;
								recent_time=c_time_d[ii];
							}
						}
						
						
					}

					ii += interval;
				} while(ii<size);
				
				ending: rb_ary_push(full_array, rb_ary_new3(2, peak_array_t, peak_array));
				rb_ary_push(full_array, rb_ary_new3(2,base_array_t, base_array));
				rb_ary_push(full_array, recent_time); 
				rb_ary_push(peak_array_diff, rb_ary_new3(2,INT2NUM(cur_ii_peak),c_val_d[cur_ii_peak]));
				rb_ary_push(base_array_diff, rb_ary_new3(2,INT2NUM(cur_ii_base),c_val_d[cur_ii_base]));
				rb_ary_push(full_array, peak_array_diff); 
				rb_ary_push(full_array, base_array_diff); 
				return full_array;
        
        }"
    end
end	




=begin

def read_data(path) 
	data=[]
	mid_data=[]
	csv_contents = CSV.parse(File.read(path, converters: :numeric))
	1.times{csv_contents.slice!(0)}
	csv_contents.each_with_index do |content, i|
		real1 = content[0].to_i   	#timestamp
		real7 = content[6].to_f		#mid b
		real8 = content[7].to_f		#open b
		real9 = content[8].to_f		#high b
		real10 = content[9].to_f	#low b
		real11 = content[10].to_f	#close b
		real12 = content[11].to_f	#close ask
		data.push([real1,real7,real8,real9,real10,real11,real12, i])
		mid_data.push(real7)
	end

	return data,mid_data

end


data_path = "/home/jwong/Documents/ruby/marketdata/processed_data/EURUSD/01-hours/full_2015-03-31_year.csv"

data1, data2 = read_data(data_path)
data2.clear
data1_t = data1.transpose
iterations = 10000

timestamp_d = data1_t[0]
close_d = data1_t[5]
interval = 24
s_interval = (interval/6).to_i




		
cheese = Peak.new()
pie = cheese.find_peak_c(timestamp_d, close_d,[], [],[],[],[],[], 0, interval, s_interval)

time2 = timestamp_d[0..800]
close2 = close_d[0..800]
time3 = timestamp_d[700..-1]
close3 = close_d[700..-1]




test1 = Peak_evaluate.new(interval, s_interval, 4)
results = test1.peak_find_slope(time2,close2)
results2 = test1.peak_find_slope(time3,close3)

pparray = test1.prev_peak_t
p pparray == pie[0][0]

p results2[0][0].count
p results2==pie


=end