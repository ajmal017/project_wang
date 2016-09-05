=begin
	
1. Check to see if @@ma_set_n.count==0     if there exists an MA set already, if yes, then we only do MA for last three values
2. Search the dataset for the time that is before the third last time
3. Remove the last two MA_SET_N values
4. Find peaks and bases. If peak and base set above 20, remove them
5. Find corssing value -> crossing value has to be redone everytime
6. Do value finding

ISSUE : When it comes to peak and base finding, there is a strong dependence on the size of the peak and base.
Even using a normal sine wave, the interval size makes a lot of difference to the performance of the peak-base finder

LAST TEST FILE : /ruby/test/moveing_avg_1.rb  sept 4,2016

=end




#should convert much of the process to C, peak_finding_interval should change
require_loc = "/home/jwong/Documents/ruby"
require require_loc + "/deep_dup.rb"
require require_loc + "/machine_learn/peak_find_v17_2.rb"
require require_loc + "/arraymath.rb"
require 'inline'
require 'benchmark'




class Move_average
	attr_accessor :ma_set,:time_since_peak, :time_since_peak_t, :time_since_peak_ii, :time_since_valley, :time_since_valley_t, :time_since_valley_ii, :recent_time, :cross_time, :interval, :interval_peaks, :interval_base, :prev_peak_ind_diff, :prev_base_ind_diff
	def initialize(average_movement)
		self.ma_set = []
		self.time_since_peak_t=[]
		self.time_since_valley_t=[]
		self.time_since_peak=[]
		self.time_since_valley=[]
		self.time_since_peak_ii=[]
		self.time_since_valley_ii=[]
		self.cross_time = []
		self.recent_time=0
		self.interval = average_movement
		self.prev_peak_ind_diff =[]
		self.prev_base_ind_diff =[]
	@m_timestamp, @m_expected_v,@m_ob_ex_diff, @m_ob_ex_avg, @m_ob_ex_max, @m_sum_pos, @m_sum_neg, @m_std_dev = 0,1,2,3,4,5,6,7
	@m_diff_more_stddev_two_times, @m_diff_more_stddev_one_times, @m_diff_more_stddev_half_times, @m_diff_less_stddev_tenth =8,9,10,11
	@m_current_pos, @m_current_neg = 12,13
	@m_recent_24_hours_pos_neg, @m_recent_12_hours_pos_neg, @m_curr_less_avg = 14, 15,16
	end


	def moving_averages(dataset_time,dataset_val, max_ma_set=700)
		@@ma_set_n = self.ma_set.dup
		average_movement = self.interval
		total_columns = 17 #the total number of columns noted here
		cross_up_down, cross_index = 0,1  
		up_cross, down_cross = "up_cross", "down_cross"
		peak_valley_index, peak_valley_value = 0,1
		
		timestamp_t,mid_b,open_b,high_b,low_b, close_b,close_ask,candle_location, candle_location_2_n,time_convert = 0,1,2,3,4,5,6,7,8,3600
		#dataset_t = (dataset.transpose).dup
		#dataset_time = dataset_t[timestamp_t].dup
		#dataset_val = dataset_t[close_b].dup
		#dataset.clear
		#dataset_t.clear
		#dataset = dataset_val
		dataset_count = dataset_time.count
### get most recent time, then obtain @@ma_set_n
		if @@ma_set_n.count==0
			dd=average_movement-1
			@@ma_set_n =Array.new(average_movement-1){Array.new(3,0)}  #new column, timestamp
			
		else
			most_recent_time = @@ma_set_n[-3][@m_timestamp]
			dd = dataset_count-1
			dd-=1 until dataset_time[dd]<=most_recent_time
			dd+=1 #we move one time up because the most recent time is already included in the ma_set_new
			2.times{@@ma_set_n.slice!(-1)}
		end
		while dd<dataset_count
				dd_start = dd-average_movement+1
				ma_value = dataset_val[dd_start..dd].avg 
				ma_observe_expect_diff = dataset_val[dd]-ma_value  #differece is observed - expected
				@@ma_set_n.push([dataset_time[dd], ma_value.round(8),ma_observe_expect_diff.round(8)])
			dd+=1
		end
		
		@@ma_set_n.shift until @@ma_set_n.count <= max_ma_set #shift (remove first value ) if over 700 hours, about 29 days
		self.ma_set = @@ma_set_n.deep_dup
#		@@ma_set_n
		

		#dataset.clear
		#dataset_time.clear

### obtain peak base values
 
		ma_set_tr = (@@ma_set_n.transpose).deep_dup
		ma_time = ma_set_tr[@m_timestamp].deep_dup
		ma_val = ma_set_tr[@m_expected_v].deep_dup
		#no need to create index / candle location values because no trimming performed
		#now to create meta-analysis
		ma_set_count = @@ma_set_n.count
			#this will acquire all the changes in up down crossing cycle
		peak_finding_interval = 8 #16 hours in between, so set at 8
		peak_avg_interval =3


		time_since_peak = self.time_since_peak.deep_dup
		time_since_valley = self.time_since_valley.deep_dup
		time_since_peak_t = self.time_since_peak_t.deep_dup
		time_since_valley_t = self.time_since_valley_t.deep_dup
		prev_peak_ind_diff = self.prev_peak_ind_diff.deep_dup  #the most recent/last value would be the distance from peak to current, it needs to be removed
		prev_base_ind_diff = self.prev_base_ind_diff.deep_dup

		prev_peak_ind_diff.pop if prev_peak_ind_diff.count>=1
		prev_base_ind_diff.pop if prev_base_ind_diff.count>=1


		current_time = self.recent_time
		until time_since_peak.count <=30
			(time_since_peak, time_since_peak_t) = [time_since_peak, time_since_peak_t].each {|x| x; x.shift}
		end
		until (time_since_valley.count <=30) 
		( time_since_valley, time_since_valley_t) = [time_since_valley, time_since_valley_t].each{|x| x; x.shift}	
		end
		
		prev_peak_ind_diff.shift until prev_peak_ind_diff.count <= 25
		prev_base_ind_diff.shift until prev_base_ind_diff.count <= 25

		ma_peak_class1 = Peak.new()
		result_peak = ma_peak_class1.find_peak_c(ma_time, ma_val, time_since_peak_t, time_since_peak, time_since_valley_t, time_since_valley, prev_peak_ind_diff, prev_base_ind_diff, current_time, peak_finding_interval, peak_avg_interval)
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
		p result_peak[0][0]
		#p result_peak[1][0]
		self.time_since_peak_t = result_peak[0][0].compact.deep_dup
		self.time_since_peak = result_peak[0][1].compact.deep_dup
		self.time_since_valley_t = result_peak[1][0].compact.deep_dup
		self.time_since_valley = result_peak[1][1].compact.deep_dup
		self.prev_peak_ind_diff = result_peak[3].compact.deep_dup
		self.prev_base_ind_diff = result_peak[4].compact.deep_dup
		
		self.recent_time = result_peak[2].deep_dup
		
		prev_peak_ind_diff = result_peak[3].compact.dup
		prev_base_ind_diff = result_peak[4].compact.dup
		
		result_peak.clear

###end peak base find
### find crossing value
		ma_tt_start =average_movement+peak_finding_interval	
		first_crossed_list = @@ma_set_n[(average_movement+2)][@m_ob_ex_diff]>=0 ? [up_cross,ma_tt_start] : [down_cross,ma_tt_start] 				#average_movement+2 to avoid the zeroes at the front
		time_since_last_crossed =Array.new(1){Array.new(first_crossed_list)}	#we can check up to 2 previous histories of crossing the positive negative boundary. 
		#Will only include 1 previous histories for now because we're only processing a limited number of days #once we increase the number of days processed, we can increase the array beyond 2 recent history numbers
		
		
		temp_ma_set_0 = ma_set_tr[@m_expected_v]
		#the peak finding is performed by checking if the center value is lower/higher between the start point and end point. Then we search for a min or max value
		(ma_tt_start..ma_set_count-peak_finding_interval-1).step(peak_finding_interval) do |ma_tt|	
=begin
			previous_tt = (ma_tt-peak_finding_interval)
			after_tt = (ma_tt+peak_finding_interval)
			if temp_ma_set_0[previous_tt]<temp_ma_set_0[ma_tt] && temp_ma_set_0[after_tt]<temp_ma_set_0[ma_tt]
				index_ma_tt_peak = previous_tt+ (temp_ma_set_0[previous_tt..after_tt].rindex(temp_ma_set_0[previous_tt..after_tt].max)) #ma_set_count minus is used to get the distance from current point 
				time_since_peak.push([temp_ma_set_0[index_ma_tt_peak],index_ma_tt_peak]) if time_since_peak[-1][peak_valley_index]!=index_ma_tt_peak
			elsif temp_ma_set_0[previous_tt]>temp_ma_set_0[ma_tt] && temp_ma_set_0[after_tt]>temp_ma_set_0[ma_tt]
				index_ma_tt_valley = previous_tt+ (temp_ma_set_0[previous_tt..after_tt].rindex(temp_ma_set_0[previous_tt..after_tt].min))
				time_since_valley.push([temp_ma_set_0[index_ma_tt_valley],index_ma_tt_valley]) if time_since_valley[-1][peak_valley_index]!=index_ma_tt_valley
			end
=end
			#to find crossover
			if @@ma_set_n[ma_tt][@m_ob_ex_diff]>0 && time_since_last_crossed[-1][cross_up_down]==down_cross
				time_since_last_crossed.push([up_cross,ma_tt]) 
			elsif @@ma_set_n[ma_tt][@m_ob_ex_diff]<0 && time_since_last_crossed[-1][cross_up_down]==up_cross
				time_since_last_crossed.push([down_cross,ma_tt])
			end
		end			# end for loopwhenver @@ma_set_n switches from positive to negative, and find peaks. 
		
=begin
		ma_tt_start =average_movement+peak_finding_interval	
		if time_since_peak.count ==0
			time_since_peak_t = [ma_time[ma_tt_start]]
			time_since_peak =[@@ma_set_n[average_movement+2][@m_expected_v]]
			time_since_peak_ii = [ma_tt_start]
		end
		if  time_since_valley.count == 0
			time_since_valley_t = [ma_time[ma_tt_start]]
			time_since_valley = [@@ma_set_n[average_movement+2][@m_expected_v]]
			time_since_valley_ii = [ma_tt_start]
		end
=end

	#	time_since_peak.slice!(0) if time_since_peak.count>=3 
	#	time_since_valley.slice!(0) if time_since_valley.count>=3

		last_peak = (prev_peak_ind_diff.pop)[peak_valley_index]  #will not include final peak distance into overall average #not including final peak because it could include the most recent value and hence inaccurate
		last_valley = (prev_base_ind_diff.pop)[peak_valley_index] #same goes for base. The last value is inaccurate ^^^

		time_since_last_crossed.slice!(0) if time_since_last_crossed.count>=3
		peak_count, valley_count, cross_count = prev_peak_ind_diff.count, prev_base_ind_diff.count, time_since_last_crossed.count
		span_peak, span_valley, span_cross = 0.0, 0.0, 0.0
		prev_peak_ind_diff.each{|x| span_peak+=x[peak_valley_index]}
		prev_base_ind_diff.each{|x| span_valley+=x[peak_valley_index]}
		(0..cross_count-2).each{|x| span_cross+=(time_since_last_crossed[x][cross_index]-time_since_last_crossed[x+1][cross_index]).abs}
		span_peak/=(peak_count-1) if peak_count!=1
		span_valley/=(valley_count-1) if valley_count!=1
		span_cross/=(cross_count-1) if cross_count!=1



=begin
	#I dont think the peak_count or valley count will be any less than 2
		if span_peak<=0.1 && peak_count==1
			max_p = temp_ma_set_0.max
			ind_p = temp_ma_set_0.rindex(max_p)
			time_since_peak.push([ma_time[ind_p],max_p])  #give timestamp and max val
			#time_since_peak.push([max_p,ind_p])
			#span_peak = (ma_set_count-ind_p).to_f
			span_peak = ma_time[-1] - ma_time[ind_p]
		end
		if span_valley<=0.1 && valley_count==1
			min_v = temp_ma_set_0.min
			ind_v = temp_ma_set_0.rindex(min_v)
			time_since_valley.push([ma_time[ind_v],min_v])
			#time_since_valley.push([min_v,ind_v])
			#span_valley = (ma_set_count-ind_v).to_f
		end
=end
		span_cross=ma_set_count if time_since_last_crossed.count==1
		peak_count, valley_count, cross_count, max_p, ind_p,min_v,ind_v,temp_ma_set_0 = nil,nil,nil,nil,nil,nil,nil,nil

		@@ma_set_n.each {|x|(total_columns-2).times{x.push(0)}} #it's important to include the columns before transposing because the first (average_movement)total columns are 0. total_columns-2 is because the first two are already included, eg m_expected_v,@m_ob_ex_diff
		recent_24_hours, recent_12_hours = 24.0, 12.0
		dd1=average_movement#(@@ma_set_n.count-1) # we only need the final value for backtest. For compile_analytics, use -->	# dd1=average_movement-1
		temp_ma_set=@@ma_set_n.transpose
		while dd1<ma_set_count	
			dd_start = dd1-average_movement+1
			ma_avg = temp_ma_set[@m_ob_ex_diff][dd_start..dd1].avg #ArrayMath.new.sum(temp_ma_set[@m_ob_ex_diff][dd_start..dd1])/average_movement.to_f   #@@ma_set_n[dd_start..dd1].inject(0.0) { |sum, el| sum + el[@m_ob_ex_diff] } / average_movement  #calculates average difference between observed and expected
			ma_max_val = temp_ma_set[@m_expected_v][dd_start..dd1].max
			ma_min_val = temp_ma_set[@m_expected_v][dd_start..dd1].min
			ma_max_index = dd_start + temp_ma_set[@m_expected_v][dd_start..dd1].rindex(ma_max_val)
			ma_min_index = dd_start + temp_ma_set[@m_expected_v][dd_start..dd1].rindex(ma_min_val)

			ma_max = ma_max_val-temp_ma_set[@m_expected_v][dd1] #calculates maximum difference between observed and expected
			ma_min = ma_min_val-temp_ma_set[@m_expected_v][dd1] ## NEED TO ADD THIS IN
			
			ma_variance = @@ma_set_n[dd_start..dd1].inject(0.0) {|accum, i| accum +(i[@m_ob_ex_diff]-ma_avg)**2 }
			ma_variance/= average_movement
			ma_std_dev = Math.sqrt(ma_variance)
			proportion_ex_diff_to_std_dev = ((@@ma_set_n[dd1][@m_ob_ex_diff]-ma_std_dev)/ma_std_dev).round(8) #use the proportion instead of the plain std value
			
			since_span_peak_p = (((dd1-last_peak).to_f)/span_peak).round(4)
			since_span_valley_p = (((dd1-last_valley).to_f)/span_valley).round(4)


			#since_span_peak_p = span_peak>0 ? ((time_since_peak[-1][peak_valley_index]).to_f/span_peak).round(4) : 0
			#since_span_valley_p = span_valley>0 ? ((time_since_valley[-1][peak_valley_index]).to_f/span_valley).round(4) : 0
			since_span_crossed_p = span_cross>0 ? ((time_since_last_crossed[-1][cross_index]).to_f/span_cross).round(4) : 0
		
			
			ma_sum_recent_max = temp_ma_set[@m_ob_ex_diff][ma_max_index..dd1].sum 
			ma_sum_recent_min = temp_ma_set[@m_ob_ex_diff][ma_min_index..dd1].sum 
				
			dd_recent_24_hours, dd_recent_12_hours = (dd1-recent_24_hours+1), (dd1-recent_12_hours+1)

			ma_avg_recent_24_hours = temp_ma_set[@m_ob_ex_diff][dd_recent_24_hours..dd1].avg 
			ma_avg_recent_12_hours = temp_ma_set[@m_ob_ex_diff][dd_recent_12_hours..dd1].avg 
			
			index_recent_cross = time_since_last_crossed[-1][cross_index]
			index_2nd_recent_cross = time_since_last_crossed.count>1 ? time_since_last_crossed[-2][cross_index] : index_recent_cross
			
			@@ma_set_n[dd1][@m_ob_ex_avg],@@ma_set_n[dd1][@m_ob_ex_max] =  ma_avg.round(8), ma_max.round(8)

			
			# (temp_ma_set[@m_expected_v][dd1]-self.time_since_peak[-1][peak_valley_value]) difference between current/final expected V and last peak value
			# (temp_ma_set[@m_expected_v][dd1]-self.time_since_peak[-1][peak_valley_value]) difference between current/final expected V and second last peak value

			@@ma_set_n[dd1][@m_sum_pos], @@ma_set_n[dd1][@m_sum_neg], @@ma_set_n[dd1][@m_std_dev] = (temp_ma_set[@m_expected_v][dd1]-self.time_since_peak[-1]), (temp_ma_set[@m_expected_v][dd1]-self.time_since_peak[-2]), proportion_ex_diff_to_std_dev
			@@ma_set_n[dd1][@m_diff_more_stddev_two_times], @@ma_set_n[dd1][@m_diff_more_stddev_one_times] =temp_ma_set[@m_expected_v][dd1]-self.time_since_valley[-1],temp_ma_set[@m_expected_v][dd1]-self.time_since_valley[-2]
			@@ma_set_n[dd1][@m_diff_more_stddev_half_times], @@ma_set_n[dd1][@m_diff_less_stddev_tenth] = since_span_peak_p, since_span_valley_p
			
			@@ma_set_n[dd1][@m_current_pos], @@ma_set_n[dd1][@m_current_neg] = ma_sum_recent_max, ma_sum_recent_min
			@@ma_set_n[dd1][@m_recent_24_hours_pos_neg], @@ma_set_n[dd1][@m_recent_12_hours_pos_neg] = ma_avg_recent_24_hours,ma_avg_recent_12_hours 
			@@ma_set_n[dd1][@m_curr_less_avg] = since_span_crossed_p
			
			dd1+=1
		end

		return  @@ma_set_n
		
		

	end

	def moving_average_diff(val1, val2)
		return 0
	end
	
	
end



class Cal_move_avg
# select range of items in array http://stackoverflow.com/questions/3130232/selecting-a-range-of-items-inside-an-array-in-c-sharp
# ruby array manipulation C http://clalance.blogspot.my/2011/01/writing-ruby-extensions-in-c-part-9.html
# VALUE changes https://silverhammermba.github.io/emberb/c/#numeric  

     inline :C do |builder|
        builder.c "
        
           VALUE count_ma_set(VALUE timestamp_d, VALUE value_d, VALUE prev_ma, VALUE intvl, VALUE start_point){
			/* timestamp_d is data timestamp, value_d is for data value */
				int interval = NUM2INT(intvl);
				int ii = NUM2INT(start_point);
				/*double cur_time = NUM2DBL(cur_t);*/
                int size = RARRAY_LEN(timestamp_d);
				int last_val = size-1;
				int max_size = size-interval;
                VALUE *c_time_d = RARRAY_PTR(timestamp_d);
				VALUE *c_val_d= RARRAY_PTR(value_d);
				int i ;
				double count, sum_avg_val, ma_obs_diff;
				long ma_size;
				do {
					int ii_start = (ii-interval+1);
					count=0.0;
					sum_avg_val=0.0;
					/*check if count =0 or count=1 is correct */
					for (i=ii_start; i<=ii; i++) {	
						sum_avg_val += NUM2DBL(c_val_d[i]); 
						count++;
					}
					sum_avg_val/=count;
					ma_obs_diff = NUM2DBL(c_val_d[ii])-sum_avg_val;
					ma_size = RARRAY_LEN(prev_ma);
					rb_ary_store(prev_ma, ma_size, rb_ary_new3(3,c_time_d[ii], DBL2NUM(sum_avg_val), DBL2NUM(ma_obs_diff)));
					ii++;
				}while (ii <size );
				
			return prev_ma;
				
			}"
	end
end



=begin
	PRE_VAL = dd_start..dd1
	ma_set_n[@m_timestamp]{0} -> timestamp
	ma_set_n[@m_expected_v]{1} -> Calculated ma values_v
	ma_set_n[@m_ob_ex_diff]{2} -> Difference between current value and calculated ma values_v
	ma_set_n[@m_ob_ex_avg]{3} -> Average difference of (ma_set_n[@m_ob_ex_diff]{2}) for PRE_VAL values
	ma_set_n[@m_ob_ex_max]{4} -> Max(PRE_VAL calculated ma values v) - current calculated ma value
	ma_set_n[@m_sum_pos]{5} -> difference between current/final expected V and last peak value
	ma_set_n[@m_sum_neg]{6} -> difference between current/final expected V and second last peak value
	ma_set_n[@m_std_dev]{7} -> proportion_ex_diff_to_std_dev  --> proportion of (ma_set_n[@m_ob_ex_diff]{2} - std_dev) / std_dev
	ma_set_n[@m_diff_more_stddev_two_times]{8} -> difference between current/final expected V and last base value
	ma_set_n[@m_diff_more_stddev_one_times]{9} -> difference between current/final expected V and second last base value
	ma_set_n[@m_diff_more_stddev_half_times]{10} -> since_span_peak_p
	ma_set_n[@m_diff_less_stddev_tenth]{11} -> since_span_valley_p
	ma_set_n[@m_current_pos]{12} -> ma_sum_recent_max -> sum difference values since most recent max value
	ma_set_n[@m_current_neg]{13} -> ma_sum_recent_min -> sum difference values since most recent min value
	ma_set_n[@m_recent_24_hours_pos_neg]{14} -> sum difference past 24 hours
	ma_set_n[@m_recent_12_hours_pos_neg]{15} -> sum difference past 12 hours
	ma_set_n[@m_curr_less_avg]{16} -> __
	ma_set_n[@____]{____} -> __
=end



