=begin

may9, need to normalize more values

unwritten new normalization:
use last_third_col to get avg and max
apply avg and max across the values
then using each , values above 1 will =1

added (i % 500 == 0) in ruby_train_data.c   in loc /usr/local/lib/ruby/gems/2.3.0/gems/ruby-fann-1.2.6/ext/ruby_fann

=end


require_loc = "/home/jwong/Documents/ruby"
#random forest from nimbus
require 'csv'
require 'ruby-fann'
require 'nbayes'
require 'benchmark'
require 'fastcsv'
require require_loc + "/arraymath.rb"
require require_loc + "/deep_dup.rb"

require 'ruby_native_statistics'  #require 'ruby-standard-deviation'
#data_source	= "C:/Users/J Wong/Documents/ruby/backtest/V12/EURUSD/EURUSD_V12_training_set_2.csv"	
#iris_source = "C:/Users/J Wong/Documents/ruby/data/iris.csv"

def bench(name, &block)
  time = Benchmark.realtime do
    yield block
  end
  puts "#{name}: #{time}"
end 

def read_analytics_fix(path)

	data=[]
		#csv_contents = CSV.parse(File.read(path, converters: :numeric))
		File.open(path) do |f|
	  	FastCSV.raw_parse(f) do |content|
			real1 = content[0].to_i		#Yes/No	
			real2 = content[1].to_f		#Profit_Buy
			real3 = content[2].to_f		#Profit_24_Buy
			real4 = content[3].to_f		#Profit_48_Buy
			real5 = content[4].to_f		#Profit_72_Buy
			real6 = content[5].to_i 	#Candle_loc
			real7 = content[6].to_f		#Close Bid
			real8 = content[7].to_f		#Close Ask
			real9 = content[8].to_f		#Slope
			real10 = content[9].to_f	#Slope2 
			real11 = content[10].to_f	#Error_slope
			real12 = content[11].to_f	#Intercept_slope
			real13 = content[12].to_f	#Estimated_difference_bid
			real14 = content[13].to_f	#Estimated_difference_ask
			real15 = content[14].to_f	#Buy_gain_1h_ago 
			real16 = content[15].to_f	#Buy_gain_3h_ago
			real17 = content[16].to_f	#Buy_gain_6h_ago
			real18 = content[17].to_f	#Buy_gain_12h_ago
			real19 = content[18].to_f	#Buy_gain_24h_ago
			real20 = 0 #content[19].to_f	#ma_05d_expected
			real21 = content[20].to_f	#ma_05d_observe_expected_diff
			real22 = content[21].to_f 	#ma_05d_avg_diff_obs_exp
			real23 = content[22].to_f 	#ma_05d_diff_max
			real24 = content[23].to_f  	#ma_05d_sum_pos
			real25 = content[24].to_f	#ma_05d_sum_neg
			real26 = content[25].to_f	#ma_05d_diff_std_dev
			real27 = content[26].to_f 	#ma_05d_diff_more_stddev_two_times
			real28 = content[27].to_f	#ma_05d_diff_more_stddev_one_times
			real29 = content[28].to_f	#ma_05d_diff_more_stddev_half_times
			real30 = content[29].to_f	#ma_05d_diff_less_stddev_tenth
			real31 = content[30].to_f	#ma_05d_current_positive_q
			real32 = content[31].to_f	#ma_05d_current_neg_q
			real33 = content[32].to_f	#ma_05d_recent_24_hours_pos_neg
			real34 = content[33].to_f 	#ma_05d_recent_12_hours_pos_neg
			real35 = content[34].to_f	#ma_05d_current_less_than_avg_q
			real36 = 0 #content[35].to_f	#ma_10d_expected
			real37 = content[36].to_f	#ma_10d_observe_expected_diff
			real38 = content[37].to_f	#ma_10d_avg_diff_obs_exp
			real39 = content[38].to_f	#ma_10d_diff_max
			real40 = content[39].to_f	#ma_10d_sum_pos
			real41 = content[40].to_f	#ma_10d_sum_neg
			real42 = content[41].to_f	#ma_10d_diff_std_dev
			real43 = content[42].to_f	#ma_10d_diff_more_stddev_two_times
			real44 = content[43].to_f	#ma_10d_diff_more_stddev_one_times
			real45 = content[44].to_f	#ma_10d_diff_more_stddev_half_times
			real46 = content[45].to_f	#ma_10d_diff_less_stddev_tenth
			real47 = content[46].to_f	#ma_10d_current_positive_q
			real48 = content[47].to_f	#ma_10d_current_neg_q
			real49 = content[48].to_f	#ma_10d_recent_24_hours_pos_neg
			real50 = content[49].to_f	#ma_10d_recent_12_hours_pos_neg
			real51 = content[50].to_f	#ma_10d_current_less_than_avg_q
			real52 = content[51].to_f	#j_yule_1_pred_50
			real53 = content[52].to_f	#j_yule_2_pred_51
			real54 = content[53].to_f	#j_2_yule_1_pred_52
			real55 = content[54].to_f	#j_2_yule_2_pred_53

			data.push([real1,real2,real3,real4,real5,real6,real7,real8,real9,real10,real11,real12,real13,real14,real15,
			real16,real17,real18,real19,real20,real21,real22,real23,real24,real25,real26,real27,real28,real29,real30,
			real31,real32,real33,real34,real35,real36,real37,real38,real39,real40,real41,real42,real43,real44,real45,
			real46,real47,real48,real49,real50,real51,real52,real53,real54,real55])
		end
		end
		data.slice!(0)
		return data

end 

def read_analytics_marshal_fix(path)
	data = Marshal.load(File.read(path))
	data.each {|x| x[19]=0; x[35]=0}	#ma_05d_expected  #ma_10d_expected 
	return data
end

def count_percentage_up(data, value)
	total = data.count.to_f
	counting1, count2 = data.count{|x| x>value}.to_f
	return (counting1/total).round(2)
end
def count_percentage_down(data, value)
	total = data.count.to_f
	counting2, count2 = data.count{|x| x<value}.to_f
	return (counting2/total).round(2)
end

def obtain_percentage_value_up(data, percentage, up_down = "Up", previous_checks=[])
	value = up_down == "Up" ? data.max : data.min
	prev_check_percent, prev_check_value, prev_index, prev_diff, value1 = 0,1,0,10000.0, "NA"
	if previous_checks.any? #previous checks should store previous values so no need to repeat measurements
		until prev_index>= previous_checks.count
			smaller_bigger = previous_checks[prev_index][prev_check_percent]<percentage 
			value1, prev_diff = previous_checks[prev_index][prev_check_value], previous_checks[prev_index][prev_check_percent] if (smaller_bigger && (percentage -previous_checks[prev_index][prev_check_percent]).abs<(prev_diff-percentage).abs)
			prev_index+=1
		end
		value = value1 if value1!="NA"
	end
	
	total = data.count.to_f
	counting = 0.0
	min_pip = 5
	if up_down=="Up"
		until ((counting/total)>=percentage) || value<=min_pip
			#counting= data.count{|x| x>=value}.to_f
			counting = ArrayMath.new.count_p(data,value)
			previous_checks.push([(counting/total),value]) unless (previous_checks.any? && (previous_checks.transpose)[prev_check_value].include?(value))
			value-=1
			value-=3 if percentage-(counting/total)>0.30
		end
	elsif up_down=="Down"
		until ((counting/total)>=percentage) || value>=-min_pip
			#counting= data.count{|x| x<=value}.to_f
			counting = ArrayMath.new.count_n(data,value)
			previous_checks.push([(counting/total),value]) unless (previous_checks.any? && (previous_checks.transpose)[prev_check_value].include?(value))
			value+=1
			value+=3 if percentage-(counting/total)>0.30
		end
	end
	
	return value, previous_checks

end


def normalize_std_profit(data)
		d_std = (data.stdevp)*1.5  #if we just use avg+std, it will yield a 14% of both ends, which is quite large a number
		d_avg = data.avg
		max_st_up = d_avg+d_std
		min_st_down = (d_avg-d_std).abs
		data.map! do |x| 
			if x>=0
				x/=max_st_up
				x=1 if x>1
			else
				x/=min_st_down
				x=-1 if x<-1
			end
			x
		end
		return data
end

def _run_fann_v16_(data_source, hours_in_trend=6)
	jprofit_buy_0,jprofit_24_buy_1,jprofit_48_buy_2,jprofit_72_buy_3, = 0,1,2,3																   
	jcandleloc_4,jclosebid_5,jcloseask_6,j_slope_7,j_2_slope_8,jerror_9,j_intercept_10,jest_diff_bid_slope_11,jest_diff_ask_slope_12= 4,5,6, 7, 8, 9, 10,11,12
	jbuy_1h_ago_13,jbuy_3h_ago_14,jbuy_6h_ago_15,jbuy_12h_ago_16,jbuy_24h_ago_17= 13,14,15,16,17
																																 
	j_m_expected_v_18,j_m_ob_ex_diff_19, j_m_ob_ex_avg_20, j_m_ob_ex_max_21, j_m_sum_pos_22, j_m_sum_neg_23, j_m_std_dev_24 = 18,19,20,21,22,23,24
	j_m_diff_more_stddev_two_times_25, j_m_diff_more_stddev_one_times_26, j_m_diff_more_stddev_half_times_27, j_m_diff_less_stddev_tenth_28 =25,26,27,28 
	j_m_current_pos_29, j_m_current_neg_30 = 29,30
	j_m_recent_24_hours_pos_neg_31, j_m_recent_12_hours_pos_neg_32, j_m_curr_less_avg_33 = 31,32,33

	j_m_2_expected_v_34,j_m_2_ob_ex_diff_35, j_m_2_ob_ex_avg_36, j_m_2_ob_ex_max_37, j_m_2_sum_pos_38, j_m_2_sum_neg_39, j_m_2_std_dev_40 = 34,35,36,37,38,39,40
	j_m_2_diff_more_stddev_two_times_41, j_m_2_diff_more_stddev_one_times_42, j_m_2_diff_more_stddev_half_times_43, j_m_2_diff_less_stddev_tenth_44 =41,42,43,44 
	j_m_2_current_pos_45, j_m_2_current_neg_46 = 45,46
	j_m_2_recent_24_hours_pos_neg_47, j_m_2_recent_12_hours_pos_neg_48, j_m_2_curr_less_avg_49 = 47,48,49
	j_yule_1_pred_50, j_yule_2_pred_51, j_2_yule_1_pred_52,j_2_yule_2_pred_53 = 50, 51, 52, 53
	
	marshalling = false
	if marshalling
		data_source2 = data_source.chomp('.csv')
		dataset = read_analytics_marshal_fix(data_source2)
		File.delete(data_source2)
	else
		#data_source	= "C:/Users/J Wong/Documents/ruby/backtest/V14/EURUSD/EURUSD_V14_training_set.csv"	
		#save_backtest_analytics = "C:/Users/J Wong/Documents/ruby/backtest/V12/EURUSD/EURUSD_V12_training_set_2.csv"
		dataset = read_analytics_fix(data_source)
	end
	marshalling=nil
	
	count_removal_last_hours = (hours_in_trend*12)+1 #6 for 6 hours in trend, 12 ticks per hour
	dataset = dataset[0..(dataset.count-count_removal_last_hours)] # removing the last rows where the profit is inaccurate and not reflect total hours in trend
	total_columns, total_rows_0 = dataset[0].length, dataset.count
	last_one_third_rows = ((2.0/3.0)*total_rows_0.to_f).to_i
	total_row_2 = total_rows_0 #- last_one_third_rows
	aver,maxi = 0,1
	avg_max_array =  Array.new(total_columns) { Array.new(2,0) }  #[0,0],[0,0] ...
	columns_wanted = [j_slope_7,j_2_slope_8,jerror_9,j_intercept_10,jest_diff_bid_slope_11,jest_diff_ask_slope_12, 
	jbuy_1h_ago_13,jbuy_3h_ago_14,jbuy_6h_ago_15,jbuy_12h_ago_16,jbuy_24h_ago_17,
	j_m_ob_ex_diff_19, j_m_ob_ex_avg_20, j_m_ob_ex_max_21,j_m_sum_pos_22, j_m_sum_neg_23,j_m_std_dev_24,   #j_m_expected_v_18,
	j_m_diff_more_stddev_two_times_25, j_m_diff_more_stddev_one_times_26, j_m_diff_more_stddev_half_times_27, j_m_diff_less_stddev_tenth_28,
	j_m_current_pos_29, j_m_current_neg_30,j_m_recent_24_hours_pos_neg_31, j_m_recent_12_hours_pos_neg_32, j_m_curr_less_avg_33,
	j_m_2_ob_ex_diff_35, j_m_2_ob_ex_avg_36, j_m_2_ob_ex_max_37, j_m_2_sum_pos_38, j_m_2_sum_neg_39 ,j_m_2_std_dev_40,
	j_m_2_diff_more_stddev_two_times_41, j_m_2_diff_more_stddev_one_times_42, j_m_2_diff_more_stddev_half_times_43, j_m_2_diff_less_stddev_tenth_44,
	j_m_2_current_pos_45, j_m_2_current_neg_46,j_m_2_recent_24_hours_pos_neg_47, j_m_2_recent_12_hours_pos_neg_48, j_m_2_curr_less_avg_49,
	j_yule_1_pred_50, j_yule_2_pred_51, j_2_yule_1_pred_52,j_2_yule_2_pred_53]  #j_m_2_expected_v_34,
	long, short= "Long", "Short"
	default_opposing_percentage = 0.90

	dataset_t = dataset.deep_dup.transpose
	dataset.clear
	dataset_t.slice!(0)
#	columns_wanted.each do |y|
#		avg_max_array[y][aver] = (dataset_t[y]).avg
#		avg_max_array[y][maxi] = [dataset_t[y].max, (dataset_t[y].min).abs].max
#	end

#	columns_wanted.each do |y2|
#		avg_max_array[y2][maxi]-=avg_max_array[y2][aver]
#	end

#	columns_wanted.each do |y2|
#		dataset_t[y2].map! do |x2|		
#			x2-=avg_max_array[y2][aver]
#			x2/=avg_max_array[y2][maxi]
#		end
#	end

	columns_wanted.each do |y|
		avg_max_array[y][aver] = dataset_t[y].avg
		av = avg_max_array[y][aver]
		dataset_t[y].map! do |x1|		
			x1-=av
			x1
		end	
	end

	columns_wanted.each do |y|
		avg_max_array[y][maxi] = (dataset_t[y].stdevp)*1.5
		am = avg_max_array[y][maxi]
		dataset_t[y].map! do |x2|		
			x2/=am
			x2 =1 if x2>1
			x2 =-1 if x2<-1
			x2
		end
	end

	
	row_profit_ori = dataset_t[jprofit_buy_0].map {|x| x}
	row_profit = normalize_std_profit(row_profit_ori.deep_dup)
	row_profit_up = row_profit.map {|x| x if x>0.05}.compact
	row_profit_down = row_profit.map {|x| x if x<-0.05}.compact

	total_tries = [0.45] #[0.3,0.25,0.23, 0.22,0.2,0.18,0.15,0.13] # [0.25, 0.22] # ,0.35,0.25
	up_profit, previous_up = obtain_percentage_value_up(row_profit_up, total_tries[0], "Up")
	down_profit, previous_down =obtain_percentage_value_up(row_profit_down, default_opposing_percentage, "Down")
	
	tries=0
	up_or_down="Up"
	
	[6,5,4,3,2,1,0].each do |x| #removes jprofit_buy_0,jprofit_24_buy_1,jprofit_48_buy_2,jprofit_72_buy_3, jcandleloc_4,jclosebid_5,jcloseask_6
		dataset_t.delete_at x
	end
	dataset = dataset_t.deep_dup.transpose
	dataset_t.clear


	end_value = 600 #end_value is the the length of array which we'll be testing the results against # count_removal_last_hours is due to the time gap between last prediction and first possible prediction


	random_gen = ((0..total_rows_0-end_value).to_a.sample((0.008*total_rows_0).to_i)).sort.reverse  #0.04*total this creates a random set of data to test against  586 count
	validation_set, validation_results, profit_rand_set =[],[],[]
	random_gen.each do |gg|
		validation_set<<dataset[gg]
		profit_rand_set<<row_profit_ori[gg] #don't slice row profit as it will be used in result_array  row_profit.slice!(gg)
		dataset.slice!(gg)
	end

	total_rows = dataset.count #have to calculate again after removing validation_set
	end_row = (total_rows-end_value)
	one_third_total_rows =(total_rows*0.60).ceil  #(total_rows*0.3334).ceil
	two_third_total_rows = (total_rows*0.80).ceil#(total_rows*0.6667).ceil
	dataset_1_ori = (dataset.dup)[0..one_third_total_rows]
	dataset_2_ori = (dataset.dup)[(one_third_total_rows+1)..two_third_total_rows]
	dataset_3_ori = (dataset.dup)[(two_third_total_rows+1)..end_row]
	test_set = (dataset.dup)[end_row+1..-1]
	profit_array = (row_profit_ori.dup)[total_rows_0-end_value+1..-1] # use total_rows_0 here because no slicing of row_profit, and since random_gen doesnt include end_values
	test_set.concat(validation_set)
	profit_array.concat(profit_rand_set)
		###
		#profit_array=(row_profit.dup)[(two_third_total_rows+1)..end_row]
		###
	validation_set.clear
	profit_rand_set.clear
	tot_data_col = dataset[0].count
	all_results, wanted_up_results, wanted_down_results=[], [], []
										############ start total_tries!! ############
	while tries < total_tries.count		
		if up_or_down=="Up" && tries!=0
			up_profit, previous_up = obtain_percentage_value_up(row_profit_up, total_tries[tries], up_or_down, previous_up)
		elsif up_or_down=="Down" && tries!=0
			down_profit, previous_down =obtain_percentage_value_up(row_profit_down, total_tries[tries], up_or_down, previous_down)
		end
		total_up, total_down = 0, 0
		result_array = nil
		result_array =[]
#		row_profit.each do |x|
#			if x>=up_profit
#				result_array << [x,0,0] #{}"Long"
#				total_up +=1
#			elsif x<=down_profit 
#				result_array << [0,-x,0]#{}"Short"
#				total_down+=1
#			else
#				result_array << [0,0,1]#{}"NA"
#			end
#		end
		row_profit.each do |x|
			if x>=0
				result_array << [x,0] 
				total_up +=1
			elsif x<0
				result_array << [0,-x]
				total_down+=1
			end
		end
		
		validation_results.clear
		random_gen.each do |gg|
			validation_results << result_array[gg]
			result_array.slice!(gg)
		end

		test_results = (result_array.dup)[end_row+1..-1]
		test_results.concat(validation_results)
		validation_results.clear
		if defined? fann
	#		dataset_1_ori = dataset_1_ori.zip(result_array).shuffle
	#		dataset_1_ori, result_array = dataset_1_ori.transpose
		end
		
		dataset_1, result_array_1 = dataset_1_ori.dup, (result_array.dup)[0..one_third_total_rows]
		dataset_2, result_array_2 = dataset_2_ori.dup, (result_array.dup)[(one_third_total_rows+1)..two_third_total_rows]
		dataset_3, result_array_3 = dataset_3_ori.dup, (result_array.dup)[(two_third_total_rows+1)..end_row]
		dataset_1 = dataset_1.zip(result_array_1).shuffle
		dataset_2 = dataset_2.zip(result_array_2).shuffle
		dataset_3 = dataset_3.zip(result_array_3).shuffle
		dataset_1, result_array_1 = dataset_1.transpose
		dataset_2, result_array_2 = dataset_2.transpose
		dataset_3, result_array_3 = dataset_3.transpose
		#p result_array_1[0..10]
		#sleep(20)
		result_array.clear

													####FANN TRAINING###
		hid_lay_1 = tot_data_col*2
		hid_lay_2 = tot_data_col
		hid_lay_3 = (hid_lay_2/1.5).to_i
		hid_lay_4 = (hid_lay_3/1.5).to_i
		train1 = RubyFann::TrainData.new(:inputs=>dataset_1, :desired_outputs=>result_array_1)
		train2 = RubyFann::TrainData.new(:inputs=>dataset_2, :desired_outputs=>result_array_2)
		train3 = RubyFann::TrainData.new(:inputs=>dataset_3, :desired_outputs=>result_array_3)
		#unless defined? fann
		fann = RubyFann::Standard.new(:num_inputs=>tot_data_col, :hidden_neurons=>[hid_lay_1, hid_lay_2, hid_lay_3, hid_lay_4], :num_outputs=>2)
		#end
		  	fann.randomize_weights(-1.0, 1.0)
		  	#fann.set_learning_rate(0.2)
		  	fann.set_training_algorithm(:rprop) 
		  	#fann.set_activation_function_hidden(:sigmoid_symmetric)
  			#fann.set_activation_function_output(:sigmoid_symmetric)
  		
		fann.train_on_data(train3, 200, 200, 0.01) 
		dataset_3.clear	
		result_array_3.clear
		fann.train_on_data(train1, 100, 100, 0.01) # 1000 max_epochs, 10 errors between reports and 0.1 desired MSE (mean-squared-error)   
		dataset_1.clear
		result_array_1.clear
		fann.train_on_data(train2, 100, 100, 0.01)
		dataset_2.clear
		result_array_2.clear


		##
		total_test = (test_set.count).to_f
		total_long,total_short = 0,0
		total_long_correct, total_short_correct = 0,0
		profit_long, profit_short, correct_long_min, correct_short_min = 0.0,0.0,0,0
		long_i, short_i, na_i =0,1,2
		test_set.each_index do |ii|
			result = fann.run(test_set[ii])
			curr_prob = result.max
			alt_prob = result.min
			curr_result = result.rindex(curr_prob)
			alt_result = curr_result==1 ? 0 : 1
			p "#{result}	: #{curr_result}" if ii%40==0
			long_class_prob, short_class_prob, neutral_class_prob = result[long_i], result[short_i]#, result[na_i]
			#min_prob, max_alt_prob =0.40, 0.04
			max_alt_prob = (result.min+0.0001)
			min_prob = max_alt_prob*20
			if curr_prob>=min_prob && curr_prob>0.05  #&& curr_result==long_i && short_class_prob<max_alt_prob) || (curr_prob>min_prob && curr_result == short_i && long_class_prob<max_alt_prob)
				total_long +=1 if curr_result==long_i
				total_short+=1 if curr_result==short_i
				if curr_result==long_i
					total_long_correct +=1 if test_results[ii].rindex(test_results[ii].max)==long_i
					profit_long += profit_array[ii]
					correct_long_min +=1 if profit_array[ii]>0
				elsif curr_result==short_i
					total_short_correct+=1 if test_results[ii].rindex(test_results[ii].max)==short_i
					profit_short -= profit_array[ii] 
					correct_short_min +=1 if profit_array[ii]<0
				end
			end
		end #finish up result max class
		
		percentage_correct_long = (total_long_correct.to_f/total_long.to_f).round(3)
		percentage_correct_short = (total_short_correct.to_f/total_short.to_f).round(3)
		percentage_correct_long_min = (correct_long_min.to_f/total_long.to_f).round(3)
		percentage_correct_short_min = (correct_short_min.to_f/total_short.to_f).round(3)
		average_profit_long, average_profit_short = (profit_long/(total_long.to_f)).round(1), (profit_short/(total_short.to_f)).round(1)
		
		minimum_percentage_min, minimum_percentage = 0.70,0.10
		min_0, min_1, min_2 = 25, 50, 100
		if up_or_down=="Up" && percentage_correct_long_min>=minimum_percentage_min && percentage_correct_long>=minimum_percentage
			if ((total_long>=min_0 && total_long<min_1 && average_profit_long>=20.0 && percentage_correct_long_min>=0.80) || (total_long>=min_1 && total_long<min_2 && average_profit_long>=10.0 && percentage_correct_long_min>=0.70) || (total_long>=min_2 && average_profit_long>=8.0))
				wanted_up_results.push([total_tries[tries],total_long, percentage_correct_long, percentage_correct_long_min, profit_long.round(),average_profit_long, up_profit, down_profit])
			end
		elsif up_or_down=="Down" && percentage_correct_short_min>=minimum_percentage_min && percentage_correct_short>=minimum_percentage
			if ((total_short>=min_0 && total_short<min_1 && average_profit_short>=20.0 && percentage_correct_short_min>=0.80) || (total_short>=min_1 && total_short<min_2 && average_profit_short>=10.0 && percentage_correct_long_min>=0.70) || (total_short>=min_2 && average_profit_short>=8.0))
				wanted_down_results.push([total_tries[tries],total_short, percentage_correct_short,percentage_correct_short_min, profit_short.round(),average_profit_short, up_profit, down_profit])
			end
		end
		
		all_results.push([up_or_down, total_tries[tries],total_long, percentage_correct_long, percentage_correct_long_min, profit_long.round(),average_profit_long, 
		"<<Up | Down>>", total_short, percentage_correct_short,percentage_correct_short_min, profit_short.round(),average_profit_short])

	
		test_results.clear
		#sfann=nil

		
		tries+=1
		if tries == total_tries.count && up_or_down=="Up"
			tries=0
			up_or_down="Down"
			up_profit, previous_up = obtain_percentage_value_up(row_profit_up, default_opposing_percentage, "Up", previous_up)
			down_profit, previous_down =obtain_percentage_value_up(row_profit_down, total_tries[0], "Down", previous_down)	
		end	

	end #run tries twice up_or_down
	puts "FINAL RESULTS"
	all_results.each do |x|
	print x
	puts "           "
	end

	return dataset, row_profit, wanted_up_results, wanted_down_results, all_results, avg_max_array, columns_wanted
end


def dump_fann(data_source, data_profit_source, up_profit, down_profit, dump_file)
	total_rows = data_source.count
	one_third_total_rows =(total_rows*0.60).ceil  
	two_third_total_rows = (total_rows*0.80).ceil
	result_array =[]
	data_profit_source.each do |x|
		if x>=up_profit
			result_array << "Long"
		elsif x<=down_profit 
			result_array << "Short"
		else
			result_array << "NA"
		end
	end
	dataset_1, result_array_1 = (data_source.dup)[0..one_third_total_rows], (result_array.dup)[0..one_third_total_rows]
	dataset_2, result_array_2 = (data_source.dup)[(one_third_total_rows+1)..two_third_total_rows], (result_array.dup)[(one_third_total_rows+1)..two_third_total_rows]
	dataset_3, result_array_3 = (data_source.dup)[(two_third_total_rows+1)..total_rows], (result_array.dup)[(two_third_total_rows+1)..total_rows]

		data_source.clear	
		result_array.clear

		fann = NBayes::Base.new
		total_train = 3
		for k in 0..total_train
			dataset_1.each_index do |i|
				fann.train(dataset_1[i],result_array_1[i])
			end
		end

		for k in 0..total_train+1
			dataset_2.each_index do |i|
				fann.train(dataset_2[i],result_array_2[i])
			end
		end

		for k in 0..total_train+4
			dataset_3.each_index do |i|
				nbayes.train(dataset_3[i],result_array_3[i])
			end
		end
		fann.dump(dump_file)
		return 0 
		end

def sort_results(results_list)

	setting_0, total_trade_1, per_correct_2, per_correct_min_3, profit_4, av_profit_5, up_profit_6, down_profit_7 =0,1,2,3,4,5,6,7
	if results_list.any?
		results_list_t = results_list.transpose
		ind_max_av_profit_rr = results_list_t[av_profit_5].rindex(results_list_t[av_profit_5].max)
		ind_max_per_correct_min_rr = results_list_t[per_correct_min_3].rindex(results_list_t[per_correct_min_3].max)
		return_1 = [results_list[ind_max_av_profit_rr][setting_0], results_list[ind_max_av_profit_rr][up_profit_6], results_list[ind_max_av_profit_rr][down_profit_7]]
		return_2 = [results_list[ind_max_per_correct_min_rr][setting_0], results_list[ind_max_per_correct_min_rr][up_profit_6], results_list[ind_max_per_correct_min_rr][down_profit_7]]
		return return_1, return_2
	else
		return ["NA", "NA"], ["NA", "NA"]
	end 
end


def fann_main_run(file_source, data_file, hours_in_trend=6)

	#data_file ="C:/Users/J Wong/Documents/ruby/backtest/V14/EURUSD"
	#data_source	= "#{file_source}/EURUSD_V14_training_set.csv"
	#data_source = "#{file_source}/#{data_file}"
	dataset, row_profit, up_results, down_results, final_results, avg_max_array, columns_wanted = _run_fann_v16_(data_file, hours_in_trend)
	index1_up, index2_up = sort_results(up_results)
	index1_down, index2_down = sort_results(down_results)
	up_index, down_index = [index1_up, index2_up].uniq, [index1_down, index2_down].uniq
	ind_set_0, ind_up_1, ind_down_2= 0,1,2
	up_index.each_index  do |i|
		file_name = "#{file_source}/fann/bayes_up_#{i}.yaml"
		dump_fann(dataset.dup, row_profit.dup, up_index[i][ind_up_1], up_index[i][ind_down_2], file_name) if up_index[i][ind_set_0]!="NA"
	end
	down_index.each_index  do |i|
		file_name = "#{file_source}/fann/bayes_down_#{i}.yaml"
		dump_fann(dataset.dup, row_profit.dup, down_index[i][ind_up_1], down_index[i][ind_down_2], file_name) if down_index[i][ind_set_0]!="NA"
	end
			#print dataset[-1][11..21]
			#puts " "
	
	return avg_max_array, columns_wanted
end


if __FILE__ == $0
 
	Benchmark.bm do |bm|

		bm.report do
			ruby_file = "/home/jwong/Documents/ruby" #"C:/Users/J Wong/Documents/ruby"
			data_file = ruby_file + "/backtest/V16/EURUSD"
			fann_folder = data_file + "/fann"
			data_source	= data_file + "/EURUSD_V16_training_set.csv"
			dataset, row_profit, up_results, down_results, final_results, avg_max_array, columns_wanted = _run_fann_v16_(data_source)
			index1_up, index2_up = sort_results(up_results)
			index1_down, index2_down = sort_results(down_results)
			up_index, down_index = [index1_up, index2_up].uniq, [index1_down, index2_down].uniq
			ind_set_0, ind_up_1, ind_down_2= 0,1,2
			up_index.each_index  do |i|
			#	file_name = "#{file_source}/bayes/bayes_up_#{i}.yaml"
			#	dump_nbayes(dataset.dup, row_profit.dup, up_index[i][ind_up_1], up_index[i][ind_down_2], file_name) if up_index[i][ind_set_0]!="NA"
			end
			down_index.each_index  do |i|
			#	file_name = "#{file_source}/bayes/bayes_down_#{i}.yaml"
			#	dump_nbayes(dataset.dup, row_profit.dup, down_index[i][ind_up_1], down_index[i][ind_down_2], file_name) if down_index[i][ind_set_0]!="NA"
			end
			#dump_nbayes(data_source, data_profit_source, up_profit, down_profit, dump_file)
			#save_avg_max = "#{fann_folder}/avg_max.csv"
			#save_columns_wanted = "#{fann_folder}/columns_wanted.csv"
			#CSV.open(save_avg_max, 'wb' ) do |writer| 
			#	avg_max_array.each do |d|
			#	end
			#end
			#CSV.open(save_columns_wanted, 'wb' ) do |writer| 
			#	columns_wanted.each do |d|
			#	end
			#end
		#CSV.open(save_backtest_analytics, 'wb' ) do |writer|  
	#			up_results.each do |d|
	#			writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
	#			d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
	#			d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54],d[55],d[56],d[57],d[58],d[59],
	#			d[60],d[61],d[62],d[63],d[64],d[65],d[66],d[67],d[68],d[69],d[70],d[71],d[72],d[73],d[74],d[75],d[76],d[77],d[78],d[79],d[80]]
	#			end
	#		end	

		
		end
	end
	puts " "

end



