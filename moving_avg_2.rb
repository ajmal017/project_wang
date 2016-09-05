=begin
	
1. Check to see if @@ma_set_n.count==0     if there exists an MA set already, if yes, then we only do MA for last three values
2. Search the dataset for the time that is before the third last time
3. Remove the last two MA_SET_N values
4. Find peaks and bases. If peak and base set above 20, remove them
5. Find corssing value -> crossing value has to be redone everytime
6. Do value finding

ISSUE : When it comes to peak and base finding, there is a strong dependence on the size of the peak and base.
Even using a normal sine wave, the interval size makes a lot of difference to the performance of the peak-base finder


=end




#should convert much of the process to C, peak_finding_interval should change
require_loc = "/home/jwong/Documents/ruby"
require require_loc + "/deep_dup.rb"
#require require_loc + "/machine_learn/peak_find_v17_2.rb"
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
		@@ma_set_n = []#    self.ma_set.dup
		average_movement = self.interval
		total_columns = 17 #the total number of columns noted here
		cross_up_down, cross_index = 0,1  
		up_cross, down_cross = "up_cross", "down_cross"
		peak_valley_index, peak_valley_value = 0,1

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
		@@ma_set_n = count_ma_set2(dataset_time, dataset_val, @@ma_set_n, average_movement, dd)

### obtain peak base values
 
		ma_set_tr = (@@ma_set_n.transpose)#.deep_dup
		ma_time = ma_set_tr[@m_timestamp]#.deep_dup
		ma_val = ma_set_tr[@m_expected_v]#.deep_dup
		#no need to create index / candle location values because no trimming performed
		#now to create meta-analysis

		#@@ma_set_n.shift until @@ma_set_n.count <= max_ma_set #shift (remove first value ) if over 700 hours, about 29 days
		#self.ma_set = @@ma_set_n.deep_dup


		ma_set_count = @@ma_set_n.count
			#this will acquire all the changes in up down crossing cycle
		peak_finding_interval = 8 #16 hours in between, so set at 8
		peak_avg_interval =3


		time_since_peak = self.time_since_peak.dup#.deep_dup
		time_since_valley = self.time_since_valley.dup#.deep_dup
		time_since_peak_t = self.time_since_peak_t.dup#.deep_dup
		time_since_valley_t = self.time_since_valley_t.dup#.deep_dup
		prev_peak_ind_diff = self.prev_peak_ind_diff.dup#.deep_dup  #the most recent/last value would be the distance from peak to current, it needs to be removed
		prev_base_ind_diff = self.prev_base_ind_diff.dup#.deep_dup

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

		#ma_peak_class1 = Peak.new()
		result_peak = find_peak_c2(ma_time, ma_val, time_since_peak_t, time_since_peak, time_since_valley_t, time_since_valley, prev_peak_ind_diff, prev_base_ind_diff, current_time, peak_finding_interval, peak_avg_interval)
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

		self.time_since_peak_t = result_peak[0][0].compact#.deep_dup
		self.time_since_peak = result_peak[0][1].compact#.deep_dup
		self.time_since_valley_t = result_peak[1][0].compact#.deep_dup
		self.time_since_valley = result_peak[1][1].compact#.deep_dup
		self.prev_peak_ind_diff = result_peak[3].compact#.deep_dup
		self.prev_base_ind_diff = result_peak[4].compact#.deep_dup
		
		self.recent_time = result_peak[2]#.deep_dup
		
		prev_peak_ind_diff = result_peak[3].compact.dup
		prev_base_ind_diff = result_peak[4].compact.dup
		
		#result_peak.clear

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

		span_cross=ma_set_count if time_since_last_crossed.count==1
		peak_count, valley_count, cross_count, max_p, ind_p,min_v,ind_v,temp_ma_set_0 = nil,nil,nil,nil,nil,nil,nil,nil

		@@ma_set_n.each {|x|(total_columns-2).times{x.push(0)}} #it's important to include the columns before transposing because the first (average_movement)total columns are 0. total_columns-2 is because the first two are already included, eg m_expected_v,@m_ob_ex_diff
		recent_24_hours, recent_12_hours = 24.0, 12.0
		dd1=(@@ma_set_n.count-1) # we only need the final value for backtest. For compile_analytics, use -->	# dd1=average_movement-1
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

		return  @@ma_set_n[-1][1..-1]
		
		

	end

	def moving_average_diff(val1, val2)
		return 0
	end
	
     inline :C do |builder|
        builder.c "
        
           VALUE count_ma_set2(VALUE timestamp_d, VALUE value_d, VALUE prev_ma, VALUE intvl, VALUE start_point){
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


	     inline :C do |builder|
        builder.c "
        
           VALUE find_peak_c2(VALUE timestamp_d, VALUE value_d, VALUE prev_peak_t, VALUE prev_peak_v, VALUE prev_base_t, VALUE prev_base_v, 
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




	def bench(name, &block)
	  time = Benchmark.realtime do
	    yield block
	  end
	  puts "#{name}: #{time}"
	end 

=begin
	first_list = [20,60,50,80,100,130,130,160,180,210,210,240,260,290,290,320,340,390,370,400,420]


	timea=[]
	first_list.each_index {|i| timea.push(i+1)}
	interval = 4
	dd=interval-1
	test1 = Cal_move_avg.new()
	pie = test1.count_ma_set(timea, first_list, [], interval, dd)
	p pie
	p "\n"


	first_list2 = first_list[0..-10].dup
	first_list3 = first_list[-12..-1].dup
	timea2 = timea[0..-10]
	timea3 = timea[-12..-1]

	iterations = 10000

	bench :ruby_count do 
	  	iterations.times do
	    	test2 = Cal_move_avg.new()
			pie2 = test2.count_ma_set(timea2, first_list2, [], interval, dd)
			pie3 = test2.count_ma_set(timea3, first_list3, pie2, interval, dd)

	end
	end



	bench :ruby_count2 do 
	  	iterations.times do
	  		dd=interval-1
	  		ma_new=[]
	    	while dd<timea.count
					dd_start = dd-interval+1
					ma_value = first_list[dd_start..dd].avg 
					ma_observe_expect_diff = first_list[dd]-ma_value  #differece is observed - expected
					ma_new.push([timea[dd], ma_value.round(8),ma_observe_expect_diff.round(8)])
				dd+=1
			end

	end
	end

	dd=interval-1
	test2 = Cal_move_avg.new()
	pie2 = test2.count_ma_set(timea2, first_list2, [], interval, dd)
	pie3 = test2.count_ma_set(timea3, first_list3, pie2.dup, interval, dd)

	p pie3
	p 'pie2'

  	dd=interval-1
	ma_new=[]
	   	while dd<timea.count
			dd_start = dd-interval+1
			ma_value = first_list[dd_start..dd].avg 
			ma_observe_expect_diff = first_list[dd]-ma_value  #differece is observed - expected
			ma_new.push([timea[dd], ma_value.round(8),ma_observe_expect_diff.round(8)])
			dd+=1
		end

	p ma_new
	p ma_new == pie3


=end


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
	iterations = 1000

	timestamp_d = data1_t[0]
	close_d = data1_t[5]
	interval = 24
	s_interval = (interval/6).to_i

	test3 = Move_average.new(100)
	 test3.moving_averages(timestamp_d, close_d)

	values_v = (1..5000).to_a
	time_v = values_v.deep_dup
	values_v.map! do |x| 
		x = Math.sin(x/5.0)
	end


	test4 = Move_average.new(interval)
	result = test4.moving_averages(time_v, values_v)


	bench :ruby_noCmove do 
	  	iterations.times do
		dd=interval-1
	   	while dd<values_v.count
			dd_start = dd-interval+1
			ma_value = values_v[dd_start..dd].avg 
			ma_observe_expect_diff = values_v[dd]-ma_value  #differece is observed - expected
			#ma_new.push([timea[dd], ma_value.round(8),ma_observe_expect_diff.round(8)])
			dd+=1
		end
	end
	end



	bench :ruby_Cmove do 
	  	iterations.times do
	  		dd=interval-1
			test2 = Cal_move_avg.new()
			pie2 = test2.count_ma_set(time_v, values_v, [], interval, dd)
	end
	end


	require 'csv'
	file_temp = require_loc + "/sine_wave.csv"
	CSV.open(file_temp, 'wb' ) do |writer|  
		values_v.map do |x|
			writer << [x]
		end
	end	

	file_temp = require_loc + "/sine_test.csv"
	result.insert(0,['@m_timestamp', '@m_expected_v','@m_ob_ex_diff', '@m_ob_ex_avg', '@m_ob_ex_max', '@m_sum_pos', '@m_sum_neg', '@m_std_dev',
		'@m_diff_more_stddev_two_times', '@m_diff_more_stddev_one_times', '@m_diff_more_stddev_half_times', '@m_diff_less_stddev_tenth',
		'@m_current_pos', '@m_current_neg',
		'@m_recent_24_hours_pos_neg', '@m_recent_12_hours_pos_neg', '@m_curr_less_avg'])
	CSV.open(file_temp, 'wb' ) do |writer|  
		result.each do |d|
			writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
							d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
							d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54]]
		end
	end

	p 'CLEAR CLEAR CLEAR CLEAR'


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

=begin

	time_v_1 = time_v[0..1500].deep_dup
	values_v_1 = values_v[0..1500].deep_dup
	time_v_2 = time_v[1000..2500].deep_dup
	values_v_2 = values_v[1000..2500].deep_dup
	time_v_3 = time_v[2000..3500].deep_dup
	values_v_3 = values_v[2000..3500].deep_dup
	time_v_4 = time_v[3000..4500].deep_dup
	values_v_4 = values_v[3000..4500].deep_dup
	time_v_5 = time_v[4000..5000].deep_dup
	values_v_5 = values_v[4000..5000].deep_dup

	test4_1 = Move_average.new(8)
	result_1 = test4_1.moving_averages(time_v_1, values_v_1)


	file_temp = require_loc + "/sine_test_1.csv"
	result_1.insert(0,['@m_timestamp', '@m_expected_v','@m_ob_ex_diff', '@m_ob_ex_avg', '@m_ob_ex_max', '@m_sum_pos', '@m_sum_neg', '@m_std_dev',
		'@m_diff_more_stddev_two_times', '@m_diff_more_stddev_one_times', '@m_diff_more_stddev_half_times', '@m_diff_less_stddev_tenth',
		'@m_current_pos', '@m_current_neg',
		'@m_recent_24_hours_pos_neg', '@m_recent_12_hours_pos_neg', '@m_curr_less_avg'])
	CSV.open(file_temp, 'wb' ) do |writer|  
		result_1.each do |d|
			writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
							d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
							d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54]]
		end
	end

	result_2 = test4_1.moving_averages(time_v_2, values_v_2)


	file_temp = require_loc + "/sine_test_2.csv"
	result_2.insert(0,['@m_timestamp', '@m_expected_v','@m_ob_ex_diff', '@m_ob_ex_avg', '@m_ob_ex_max', '@m_sum_pos', '@m_sum_neg', '@m_std_dev',
		'@m_diff_more_stddev_two_times', '@m_diff_more_stddev_one_times', '@m_diff_more_stddev_half_times', '@m_diff_less_stddev_tenth',
		'@m_current_pos', '@m_current_neg',
		'@m_recent_24_hours_pos_neg', '@m_recent_12_hours_pos_neg', '@m_curr_less_avg'])
	CSV.open(file_temp, 'wb' ) do |writer|  
		result_2.each do |d|
			writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
							d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
							d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54]]
		end
	end

	result_3 = test4_1.moving_averages(time_v_3, values_v_3)


	file_temp = require_loc + "/sine_test_2.csv"
	result_3.insert(0,['@m_timestamp', '@m_expected_v','@m_ob_ex_diff', '@m_ob_ex_avg', '@m_ob_ex_max', '@m_sum_pos', '@m_sum_neg', '@m_std_dev',
		'@m_diff_more_stddev_two_times', '@m_diff_more_stddev_one_times', '@m_diff_more_stddev_half_times', '@m_diff_less_stddev_tenth',
		'@m_current_pos', '@m_current_neg',
		'@m_recent_24_hours_pos_neg', '@m_recent_12_hours_pos_neg', '@m_curr_less_avg'])
	CSV.open(file_temp, 'wb' ) do |writer|  
		result_3.each do |d|
			writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
							d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
							d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54]]
		end
	end
	result_4 = test4_1.moving_averages(time_v_4, values_v_4)


	file_temp = require_loc + "/sine_test_4.csv"
	result_4.insert(0,['@m_timestamp', '@m_expected_v','@m_ob_ex_diff', '@m_ob_ex_avg', '@m_ob_ex_max', '@m_sum_pos', '@m_sum_neg', '@m_std_dev',
		'@m_diff_more_stddev_two_times', '@m_diff_more_stddev_one_times', '@m_diff_more_stddev_half_times', '@m_diff_less_stddev_tenth',
		'@m_current_pos', '@m_current_neg',
		'@m_recent_24_hours_pos_neg', '@m_recent_12_hours_pos_neg', '@m_curr_less_avg'])
	CSV.open(file_temp, 'wb' ) do |writer|  
		result_4.each do |d|
			writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
							d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
							d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54]]
		end
	end

	result_5 = test4_1.moving_averages(time_v_5, values_v_5)


	file_temp = require_loc + "/sine_test_5.csv"
	result_5.insert(0,['@m_timestamp', '@m_expected_v','@m_ob_ex_diff', '@m_ob_ex_avg', '@m_ob_ex_max', '@m_sum_pos', '@m_sum_neg', '@m_std_dev',
		'@m_diff_more_stddev_two_times', '@m_diff_more_stddev_one_times', '@m_diff_more_stddev_half_times', '@m_diff_less_stddev_tenth',
		'@m_current_pos', '@m_current_neg',
		'@m_recent_24_hours_pos_neg', '@m_recent_12_hours_pos_neg', '@m_curr_less_avg'])
	CSV.open(file_temp, 'wb' ) do |writer|  
		result_5.each do |d|
			writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
							d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
							d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54]]
		end
	end

=end




