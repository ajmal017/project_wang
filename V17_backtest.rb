#optimization search
=begin

date = "2014-05-23" Date.parse(data) is slowest, Date.strptime(date, '%Y-%m-%d') is 4x faster,  Date.civil(date[0,4].to_i, date[5,2].to_i, date[8,2].to_i) is 8x faster
obj.class == String (bad) , obj.is_a?(String) {better}
push *     faster than push or << for combining arrays
Look up GC - garbage collector
define_method ruby
Use bang! methods

moving average from compile_analytics_data_2 is wrong, it has some assumptions about future data
speed up ma by using less inject and select

get values 3,6,12,36,48 hours ago instead of 1,3,6,12,24


not enough backtest dates to test 12 hour arima, need 3 years of data to get more than 1000 training values.e

each_cons does not yield a time advantage
deep up has dup_array


1. Start with one month of data (even 3 weeks should be fine)
2. Collect final values for each day, collect for 3 months.
3. When 3 months have passed, run analysis
4. Crop data each cycle. no need to ii+=1, just shift hour1




=end
require 'gsl'
require 'fastcsv'
#require 'daru'
require 'statsample-timeseries'
require 'csv'
require 'time'
require 'date'
#require "/home/ruby/Nov_15/machine_learn/compile_data.rb"
require_loc = "/home/jwong/Documents/ruby"
#require require_loc + "/machine_learn/compile_data.rb"
#require require_loc + "/machine_learn/compile_analytics_data_5.rb"
require require_loc + "/machine_learn/nbayes_V16.rb"
require require_loc + "/deep_dup.rb"
require require_loc + "/arraymath.rb"
require require_loc + "/machine_learn/peak_find_v17_2.rb"
## require peaks

#if array in string form ->  array2 = array.gsub(/[\[\]]/,"").split(/,/).map(&:to_i)

class Backtest_Run_V_17
	def initialize(version, total_decision_needed=5, ruby_file)
		@total_decision_needed =total_decision_needed
		@version = version
		#@lag=24#lag
		@timestamp_t,@mid_b,@open_b,@high_b,@low_b, @close_b,@close_ask,@candle_location, @candle_location_2_n,@time_convert = 0,1,2,3,4,5,6,7,8,3600
		@timestamp_t_2, @close_b_2 =0,1
		@current_half_week_check= FALSE
		@jprofit_buy_0,@jprofit_24_buy_1,@jprofit_48_buy_2,@jprofit_72_buy_3, = 0,1,2,3																   
		@jcandleloc_4,@jclosebid_5,@jcloseask_6,@j_slope_7,@j_2_slope_8,@jerror_9,@j_intercept_10,@jest_diff_bid_slope_11,@jest_diff_ask_slope_12= 4,5,6, 7, 8, 9, 10,11,12
		@jbuy_1h_ago_13,@jbuy_3h_ago_14,@jbuy_6h_ago_15,@jbuy_12h_ago_16,@jbuy_24h_ago_17= 13,14,15,16,17
																																		 
		@j_m_expected_v_18,@j_m_ob_ex_diff_19, @j_m_ob_ex_avg_20, @j_m_ob_ex_max_21, @j_m_sum_pos_22, @j_m_sum_neg_23, @j_m_std_dev_24 = 18,19,20,21,22,23,24
		@j_m_diff_more_stddev_two_times_25, @j_m_diff_more_stddev_one_times_26, @j_m_diff_more_stddev_half_times_27, @j_m_diff_less_stddev_tenth_28 =25,26,27,28 
		@j_m_current_pos_29, @j_m_current_neg_30 = 29,30
		@j_m_recent_24_hours_pos_neg_31, @j_m_recent_12_hours_pos_neg_32, @j_m_curr_less_avg_33 = 31,32,33
		
		@j_m_2_expected_v_34,@j_m_2_ob_ex_diff_35, @j_m_2_ob_ex_avg_36, @j_m_2_ob_ex_max_37, @j_m_2_sum_pos_38, @j_m_2_sum_neg_39, @j_m_2_std_dev_40 = 34,35,36,37,38,39,40
		@j_m_2_diff_more_stddev_two_times_41, @j_m_2_diff_more_stddev_one_times_42, @j_m_2_diff_more_stddev_half_times_43, @j_m_2_diff_less_stddev_tenth_44 =41,42,43,44 
		@j_m_2_current_pos_45, @j_m_2_current_neg_46 = 45,46
		@j_m_2_recent_24_hours_pos_neg_47, @j_m_2_recent_12_hours_pos_neg_48, @j_m_2_curr_less_avg_49 = 47,48,49
		@j_yule_1_pred_50, @j_yule_2_pred_51, @j_2_yule_1_pred_52,@j_2_yule_2_pred_53 = 50, 51, 52, 53

		@j_prof_0, @j_prof_1_1, @j_prof_2_2, @j_prof_3_3, @j_open_4, @j_high_5, @j_low_6, @j_close_7, @j_cask_8, @j_loc_9, @j_dec_10 = 0,1,2,3,4,5,6,7,8,9,10
		@j_trade_11, @j_trade_12, @j_trade_13, @j_trade_14, @j_trade_15 = 11, 12, 13, 14, 15


	@m_expected_v,@m_ob_ex_diff, @m_ob_ex_avg, @m_ob_ex_max, @m_sum_pos, @m_sum_neg, @m_std_dev = 0,1,2,3,4,5,6
	@m_diff_more_stddev_two_times, @m_diff_more_stddev_one_times, @m_diff_more_stddev_half_times, @m_diff_less_stddev_tenth =7,8,9,10
	@m_current_pos, @m_current_neg = 11,12
	@m_recent_24_hours_pos_neg, @m_recent_12_hours_pos_neg, @m_curr_less_avg = 13, 14, 15

		@ruby_file = ruby_file#"C:/Users/J Wong/Documents/ruby"
		@compile_folder_all = "#{@ruby_file}/marketdata/"#"/home/ruby/Result_data"
		@compile_previous = "#{@compile_folder_all}/processed_data"
		
		@backtest_location = "#{@ruby_file}/backtest/#{@version}"
		@r_file_signal = "#{@backtest_location}/r-complete.txt"
		@currency_save_file = "#{@backtest_location}/currency_name.csv"
		@analytics_output_name = "#{@version}_training_set"
		@decision_output_name = "#{@version}_decision"
		@current_week = 0
		@hours_ahead_24=24
		@red,@green="#FF5959","#62FD68"
		@save_live_analytics = @backtest_location #"/home/ruby/Result_data/Parameters_11/"
		@average_analytics_count = 24737 #5mins 12times_an_hour*24_hours_a_day*6_days_a_week*12_weeks
	end

	def recreate_data(currency, source_name,hours_held, lag, yule_lag=50)
		@lag=lag
		pa_start_utc,pa_end_utc,pa_trend,pa_start_price,pa_end_price,pa_highest_price,pa_lowest_price,pa_correct_wrong,pa_closed_open,pa_confidence=0,1,2,3,4,5,6,7,8,9
		  
		timestamp_diff_epoch_held = (hours_held*60*60*1000)
		compiled_return_values = []
		backtest_decision_folder ="#{@backtest_location}/#{currency}"
		save_backtest_analytics = backtest_decision_folder + "/all_results.csv"
		analytics_folder = "#{@compile_folder_all}/analytics_data/#{@version}/#{currency}"
		@store_analytics_file = "#{analytics_folder}/#{@analytics_output_name}.csv"
		currency_training_set_file = backtest_decision_folder + "/#{currency}_#{@analytics_output_name}.csv"
		output_decision_folder = "#{backtest_decision_folder}/decision" 
		@final_output_decision_file = "#{backtest_decision_folder}/#{@version}_final_decision.csv"
		nbayes_decision_folder = "#{backtest_decision_folder}/nbayes"
		#write_currency(currency) #creates a CSV file for R to read from
		up_file_name_0 = "#{backtest_decision_folder}/bayes/bayes_up_0.yaml"
		down_file_name_0 = "#{backtest_decision_folder}/bayes/bayes_down_0.yaml"
		
		hour_path, minute_path = "#{@compile_previous}/#{currency}/01-hours/#{source_name}.csv", "#{@compile_previous}/#{currency}/05-minutes/#{source_name}.csv"
		three_hour_path, six_hour_path = "#{@compile_previous}/#{currency}/12-hours/#{source_name}.csv", "#{@compile_previous}/#{currency}/06-hours/#{source_name}.csv"
		hour_1,data_1h = read_data(hour_path)	
		minute_5,data_05 = read_data(minute_path)
		data_3 = read_long_hours(three_hour_path)			
		#hour_6,data_6 = read_data(six_hour_path)
		#data_3, hour_6 = nil, nil
		one_or_five_min=5
		pip = pip_value(currency) #obtain pip values
		@@pip = pip
		r_pip = (1.0/pip)
		spread = r_pip*5
		
		hour_1.map!.with_index do |x,i|  # give a candle_location value
			x.push(i,0)
			x[@close_ask]=(x[@close_b]+spread) #currently no ask values
			x
		end

		minute_5.map!.with_index do |y,i|  # give a candle_location value
			y.push(i)
			y[@close_ask]=(y[@close_b]+spread) #currently no ask values
			y
		end

		
		hour_1_ori = hour_1.deep_dup
		#data_3_ori = data_3.deep_dup
		#data_6_ori = data_6.deep_dup
##########		# Search begin date in ii
		begin_year, begin_month, begin_day, ii = 2015, 1, 22, 0 #2015, 7, 13, 0 # 2015, 6, 12, 2900 # 
		begin_date = Time.new(begin_year, begin_month, begin_day).to_i*1000
		ii+=1 until hour_1[ii][@timestamp_t]>= begin_date 
		current_interval_1h = hour_1[ii][@timestamp_t]
		ii01, ii01_last = 0, minute_5.count
		ii01+=1 until minute_5[ii01][@timestamp_t]>=current_interval_1h || ii01==ii01_last
		#hour_1h_n=hour_1[0..ii] 	
		#data_1h_n=data_1h[0..ii]	
		#hour_1h_n.push(minute_5[ii01]) #add first minute to the next hour because we're starting on the next hour
		ii+=1		
		current_interval_1h = hour_1[ii][@timestamp_t].to_i 
		ii3h, ii6h =0, 0
		hour_3_max = data_3[@timestamp_t_2].count-1
		ii3h+=1 until ii3h==hour_3_max || data_3[@timestamp_t_2][ii3h]>=current_interval_1h
		data_3_n = data_3[@close_b_2][0..ii3h].deep_dup
		hour_3_n_interval = data_3[@timestamp_t_2][ii3h]
		data_3_n[ii3h] = minute_5[ii01][@close_b]
		
		puts "the ii at #{Time.at(hour_1[ii][@timestamp_t]/1000).utc.year} / #{(Time.at(hour_1[ii][@timestamp_t]/1000).utc.month)} / #{(Time.at(hour_1[ii][@timestamp_t]/1000).utc.day)}"
#####################	
		
		# Start 
		prev_analytics = read_analytics_live(currency)	
		all_values = []		
		track_progress_1(hour_1[ii][@timestamp_t])	 #Just to check progress
		yule_hour_1 = yule_walker_timeseries(data_3_n, points_used =yule_lag)
		yule_hour_2 = yule_walker_timeseries(data_3_n, points_used =(yule_lag*2))
		
		#lag needs to be an array
		x_axis_1h, x_axis_1h_2, lag2=[], [], []
		lag.each do |ll|
			lag_sqrt = (0.5*Math.sqrt(ll)).ceil
			lag2.push(lag_sqrt)
			x_axis_1h.push(x_index(ll))
			x_axis_1h_2.push(x_index(lag_sqrt))
		end

		moving_avg_days = [1,2,5,10] #try to arrange this from small to large
		total_ma = {}
					
		interval = 5
		s_interval= 2
		interval_1 = 12
		s_interval_1 = 6

		peak_1 = Peak_evaluate.new(interval, s_interval, 4)     #initialize peak evaluation  initialize(width, minor_width, second_dir =4), peak_find_slope(dataset)
		peak_2 = Peak_evaluate.new(interval_1, s_interval_1, 4) 
 
		p minute_5.count

		current_ii = ii
		last_val = ((hour_1.count)/2).to_i


		hour_1h_n=hour_1[0..ii-1].deep_dup  
		data_1h_n=data_1h[0..ii-1].deep_dup		#the mid_value can be corrected later			

		update_final_ii = 0

		all_time = []
		while current_ii<last_val  # ii30<minute_30.count && 	#here's where the action starts

			if (week_check(current_interval_1h) && all_values.count>=700)#@average_analytics_count) #|| half_week_check(current_interval_1h))
			#count_compiled = all_values.any? ? all_values.count : 0
				unless false #count_compiled>=@average_analytics_count
#					write_analytics_live(currency, prev_analytics.dup)
#					prev_analytics.clear

					variable_names=['profit_buy','profit_24_buy', 'profit_48_buy', 'profit_72_buy',
					'hour_1h_n[-1][@open_b]','hour_1h_n[-1][@high_b]','hour_1h_n[-1][@low_b]','hour_1h_n[-1][@close_b]','hour_1h_n[-1][@close_ask]','hour_1h_n[-1][@candle_location]','[]',
						'buy_1h', 'buy_3h', 'buy_6h', 'buy_12h', 'buy_24h',
					'regression_slope','errors','intercept_diff','est_diff_bid_slope','est_diff_ask_slope','regression_slope2','chisq_2','regression_slope2/cov00_2',
					'regression_slope_TWO','errors_TWO','intercept_diff_TWO','est_diff_bid_slope_TWO','est_diff_ask_slope_TWO','regression_slope2_TWO','chisq_2_TWO','regression_slope2/cov00_2_TWO',
					'regression_slope_THREE','errors_THREE','intercept_diff_THREE','est_diff_bid_slope_THREE','est_diff_ask_slope_THREE','regression_slope2_THREE','chisq_2_THREE','regression_slope2/cov00_2_THREE',
					'regression_slope_FOUR','errors_FOUR','intercept_diff_FOUR','est_diff_bid_slope_FOUR','est_diff_ask_slope_FOUR','regression_slope2_FOUR','chisq_2_FOUR','regression_slope2/cov00_2_FOUR',
					'regression_slope_FIVE','errors_FIVE','intercept_diff_FIVE','est_diff_bid_slope_FIVE','est_diff_ask_slope_FIVE','regression_slope2_FIVE','chisq_2_FIVE','regression_slope2/cov00_2_FIVE',
					'pp1_1_regression_slope','pp1_1_errors','pp1_1_intercept_diff','pp1_1_est_diff_bid_slope','pp1_1_est_diff_ask_slope','pp1_1_regression_slope2','pp1_1_chisq_2','pp1_1_regression_slope2/cov00_2','pp1_1_lag_v' , 
					'pp2_1_regression_slope','pp2_1_errors','pp2_1_intercept_diff','pp2_1_est_diff_bid_slope','pp2_1_est_diff_ask_slope','pp2_1_regression_slope2','pp2_1_chisq_2','pp2_1_regression_slope2/cov00_2','pp2_1_lag_v' ,
					'bb1_1_regression_slope','bb1_1_errors','bb1_1_intercept_diff','bb1_1_est_diff_bid_slope','bb1_1_est_diff_ask_slope','bb1_1_regression_slope2','bb1_1_chisq_2','bb1_1_regression_slope2/cov00_2','bb1_1_lag_v' , 
					'bb2_1_regression_slope','bb2_1_errors','bb2_1_intercept_diff','bb2_1_est_diff_bid_slope','bb2_1_est_diff_ask_slope','bb2_1_regression_slope2','bb2_1_chisq_2','bb2_1_regression_slope2/cov00_2','bb2_1_lag_v' ,
					'pp1_2_regression_slope','pp1_2_errors','pp1_2_intercept_diff','pp1_2_est_diff_bid_slope','pp1_2_est_diff_ask_slope','pp1_2_regression_slope2','pp1_2_chisq_2','pp1_2_regression_slope2/cov00_2','pp1_2_lag_v' , 
					'pp2_2_regression_slope','pp2_2_errors','pp2_2_intercept_diff','pp2_2_est_diff_bid_slope','pp2_2_est_diff_ask_slope','pp2_2_regression_slope2','pp2_2_chisq_2','pp2_2_regression_slope2/cov00_2','pp2_2_lag_v' ,
					'bb1_2_regression_slope','bb1_2_errors','bb1_2_intercept_diff','bb1_2_est_diff_bid_slope','bb1_2_est_diff_ask_slope','bb1_2_regression_slope2','bb1_2_chisq_2','bb1_2_regression_slope2/cov00_2','bb1_2_lag_v' , 
					'bb2_2_regression_slope','bb2_2_errors','bb2_2_intercept_diff','bb2_2_est_diff_bid_slope','bb2_2_est_diff_ask_slope','bb2_2_regression_slope2','bb2_2_chisq_2','bb2_2_regression_slope2/cov00_2','bb2_2_lag_v' ,
					'm_1_expected_v','m_1_ob_ex_diff', 'm_1_ob_ex_avg', 'm_1_ob_ex_max', 'm_1_sum_pos', 'm_1_sum_neg', 'm_1_std_dev',
					'm_1_diff_more_stddev_two_times', 'm_1_diff_more_stddev_one_times', 'm_1_diff_more_stddev_half_times', 'm_1_diff_less_stddev_tenth',
					'm_1_current_pos','m_1_current_neg',
					'm_1_recent_24_hours_pos_neg', 'm_1_recent_12_hours_pos_neg', 'm_1_curr_less_avg',
					'm_2_expected_v','m_2_ob_ex_diff', 'm_2_ob_ex_avg', 'm_2_ob_ex_max', 'm_2_sum_pos', 'm_2_sum_neg', 'm_2_std_dev',
					'm_2_diff_more_stddev_two_times', 'm_2_diff_more_stddev_one_times', 'm_2_diff_more_stddev_half_times', 'm_2_diff_less_stddev_tenth',
					'm_2_current_pos','m_2_current_neg',
					'm_2_recent_24_hours_pos_neg', 'm_2_recent_12_hours_pos_neg', 'm_2_curr_less_avg',
					'm_3_expected_v','m_3_ob_ex_diff', 'm_3_ob_ex_avg', 'm_3_ob_ex_max', 'm_3_sum_pos', 'm_3_sum_neg', 'm_3_std_dev',
					'm_3_diff_more_stddev_two_times', 'm_3_diff_more_stddev_one_times', 'm_3_diff_more_stddev_half_times', 'm_3_diff_less_stddev_tenth',
					'm_3_current_pos','m_3_current_neg',
					'm_3_recent_24_hours_pos_neg', 'm_3_recent_12_hours_pos_neg', 'm_3_curr_less_avg',
					'm_4_expected_v','m_4_ob_ex_diff', 'm_4_ob_ex_avg', 'm_4_ob_ex_max', 'm_4_sum_pos', 'm_4_sum_neg', 'm_4_std_dev',
					'm_4_diff_more_stddev_two_times', 'm_4_diff_more_stddev_one_times', 'm_4_diff_more_stddev_half_times', 'm_4_diff_less_stddev_tenth',
					'm_4_current_pos','m_4_current_neg',
					'm_4_recent_24_hours_pos_neg', 'm_4_recent_12_hours_pos_neg', 'm_4_curr_less_avg',
					'predicted_1_h','predicted_2_h','predicted_1_h2','predicted_2_h2']


					all_values.insert(0,variable_names)

						temp_file = @ruby_file + "/delete_this.csv"
						CSV.open(temp_file, 'wb' ) do |writer| 
							all_values.each do |d|
								writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],
								d[20],d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
								d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54],d[55],d[56],d[57],d[58],d[59],
								d[60],d[61],d[62],d[63],d[64],d[65],d[66],d[67],d[68],d[69],d[70],d[71],d[72],d[73],d[74],d[75],d[76],d[77],d[78],d[79],
								d[80],d[81],d[82],d[83],d[84],d[85],d[86],d[87],d[88],d[89],d[90],d[91],d[92],d[93],d[94],d[95],d[96],d[97],d[98],d[99],
								d[100],d[101],d[102],d[103],d[104],d[105],d[106],d[107],d[108],d[109],d[110],d[111],d[112],d[113],d[114],d[115],d[116],d[117],d[118],d[119],
								d[120],d[121],d[122],d[123],d[124],d[125],d[126],d[127],d[128],d[129],d[130],d[131],d[132],d[133],d[134],d[135],d[136],d[137],d[138],d[139],
								d[140],d[141],d[142],d[143],d[144],d[145],d[146],d[147],d[148],d[149],d[150],d[151],d[152],d[153],d[154],d[155],d[156],d[157],d[158],d[159],
								d[160],d[161],d[162],d[163],d[164],d[165],d[166],d[167],d[168],d[169],d[170],d[171],d[172],d[173],d[174],d[175],d[176],d[177],d[178],d[179],
								d[180],d[181],d[182],d[183],d[184],d[185],d[186],d[187],d[188],d[189],d[190],d[191],d[192],d[193],d[194],d[195],d[196],d[197],d[198],d[199],
								d[200],d[201],d[202],d[203],d[204],d[205],d[206],d[207],d[208],d[209],d[210],d[211],d[212],d[213],d[214],d[215],d[216],d[217],d[218],d[219],
								d[220],d[221],d[222],d[223],d[224],d[225],d[226],d[227],d[228],d[229],d[230],d[231],d[232],d[233],d[234],d[235],d[236],d[237],d[238],d[239]]
							end
						end



					all_values.shift if all_values.count>@average_analytics_count

					exit()
				else
					 
					all_values.each do |x|
						x.insert(0,0)
					end
					all_values.insert(0,["Yes/No", "Profit_Buy","Profit_24_Buy","Profit_48_Buy","Profit_72_Buy",
					"Candle_loc","Close Bid","Close Ask","Slope","Slope2","Error_slope","Intercept_slope","Estimated_difference_bid","Estimated_difference_ask",
					"Buy_gain_1h_ago", "Buy_gain_3h_ago", "Buy_gain_6h_ago", "Buy_gain_12h_ago", "Buy_gain_24h_ago", 
					"ma_05d_expected","ma_05d_observe_expected_diff","ma_05d_avg_diff_obs_exp", "ma_05d_diff_max","ma_05d_sum_pos","ma_05d_sum_neg","ma_05d_diff_std_dev",
					"ma_05d_diff_more_stddev_two_times","ma_05d_diff_more_stddev_one_times","ma_05d_diff_more_stddev_half_times","ma_05d_diff_less_stddev_tenth",
					"ma_05d_current_positive_q","ma_05d_current_neg_q","ma_05d_recent_24_hours_pos_neg","ma_05d_recent_12_hours_pos_neg", "ma_05d_current_less_than_avg_q",
					"ma_10d_expected","ma_10d_observe_expected_diff","ma_10d_avg_diff_obs_exp", "ma_10d_diff_max","ma_10d_sum_pos","ma_10d_sum_neg","ma_10d_diff_std_dev",
					"ma_10d_diff_more_stddev_two_times","ma_10d_diff_more_stddev_one_times","ma_10d_diff_more_stddev_half_times","ma_10d_diff_less_stddev_tenth",
					"ma_10d_current_positive_q","ma_10d_current_neg_q","ma_10d_recent_24_hours_pos_neg","ma_10d_recent_12_hours_pos_neg", "ma_10d_current_less_than_avg_q", 
					"yule_pred_1", "yule_pred_2","yule_pred_1_2","yule_pred_2_2"])
					CSV.open(save_backtest_analytics, 'wb' ) do |writer|  
						all_values.each do |d|
						writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],
						d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34],d[35],d[36],d[37],d[38],d[39],
						d[40],d[41],d[42],d[43],d[44],d[45],d[46],d[47],d[48],d[49],d[50],d[51],d[52],d[53],d[54]] #,d[55],d[56],d[57],d[58],d[59],
						#d[60],d[61],d[62],d[63],d[64],d[65],d[66],d[67],d[68],d[69],d[70],d[71],d[72],d[73],d[74],d[75],d[76],d[77],d[78],d[79],d[80] 
						end
					end	#end csv.open	


					if count_compiled>@average_analytics_count
						all_values=all_values[(count_compiled-(@average_analytics_count+1))..-1]
					end
					total_hours = hour_1_ori.count
					all_values.each do |x|
						hour_loc_ahead = (x[@jcandleloc_8]+hours_held)
						hour_loc_ahead=-1 if hour_loc_ahead >=total_hours	
						x[@jprofit_buy_0]=((hour_1_ori[hour_loc_ahead][@close_b]-x[@jcloseask_6])*pip).round(1)
					end
					
				end
				
				@first_array = TRUE
				# Run R for analytics
				# run_R_analytics
				# compile_R_analytcs(output_decision_folder, mininum_pass=0.6)
				# decision_mechanism = read_final_decision_file
				# Run nbayes 
				# Read R output_name
				
				
				prev_analytics = read_analytics_live(currency)  

			end
			


			track_progress_2(hour_1[ii][@timestamp_t])
			next_5_mins = 5 
			#######################################################################################################	
			###########################______ TRIM AND UPDATE VALUES AND INTERVALS _____###########################
			
			#trim data to make it faster
			#if  ii>=700 
			#	hour_1.shift
			#	data_1h.shift
			#	ii-=1
			#	ii_remainder = 500  # I use this to get a 5 day and 10 day moving average
			#	hour_1 = hour_1[(ii-ii_remainder)..-1].dup
			#	data_1h =data_1h[(ii-ii_remainder)..-1]
			#	ii30,ii=0,ii_remainder 
			#end
			
			#hour_1h_n=hour_1[0..ii-1].deep_dup  
			#hour_1h_n.push([minute_5[ii01][@timestamp_t],minute_5[ii01][@mid_b],minute_5[ii01][@open_b],
			#	minute_5[ii01][@high_b],minute_5[ii01][@low_b],minute_5[ii01][@close_b],
			#		minute_5[ii01][@close_ask],hour_1[ii][@candle_location]]) #update hour_1h_n
			hour_1h_n.push([minute_5[ii01][@timestamp_t].deep_dup,minute_5[ii01][@mid_b].deep_dup,minute_5[ii01][@open_b].deep_dup,
				minute_5[ii01][@high_b].deep_dup,minute_5[ii01][@low_b].deep_dup,minute_5[ii01][@close_b],
					minute_5[ii01][@close_ask].deep_dup,hour_1[ii][@candle_location].deep_dup]) #update hour_1h_n
			data_1h_n.push(data_1h[ii].deep_dup)
			#data_1h_n=data_1h[0..ii].deep_dup		#the mid_value can be corrected later			





			current_interval_1h = hour_1[ii][@timestamp_t].to_i	
			if current_interval_1h>hour_3_n_interval
				ii3h+=1 until ii3h>=hour_3_max || data_3[@timestamp_t_2][ii3h]>=current_interval_1h	
				hour_3_n_interval = data_3[@timestamp_t_2][ii3h]
				if  ii3h>=1500 
					ii3h_remainder = 1400  #trimming data_3
					data_3 = data_3[(ii3h-ii3h_remainder)..-1].deep_dup
					ii3h=ii3h_remainder 
				end 
				data_3_n.clear
				yule_hour_1, yule_hour_2=nil, nil				
				data_3_n = data_3[@close_b_2][0..ii3h]
				yule_hour_1 = yule_walker_timeseries(data_3_n, points_used =yule_lag)
				yule_hour_2 = yule_walker_timeseries(data_3_n, points_used =(yule_lag*2))
			end	
			
			
							
			# Require compile_data -> this compiles 90 days worth of data for analytics purposes
			
			#move 5 minutes, 5 minutes is chosen because that is the interval between each processed point
			current_open_30,current_open_1h,current_highest,current_lowest=minute_5[ii01][@open_b],hour_1[ii][@open_b],minute_5[ii01][@high_b],minute_5[ii01][@low_b]
			
			time_adjust,time_adjust_3,time_adjust_4=0,0,0
			first=1 #this indicates the first 5 minute round, no need to add 5 minutes to the first 5 minute round.
			while  ii01<minute_5.count  && minute_5[ii01][@timestamp_t]<current_interval_1h  
				if one_or_five_min==5  
					next_5_mins,plus_5=1,0
					next_5_mins=0 if first==1 #no need to add 5 minutes on the first lap because it's already 5 minutes in 
					plus_5+=1 until plus_5==next_5_mins || ii01==minute_5.count-1 || minute_5[ii01+plus_5][@timestamp_t]>=current_interval_1h  # || minute_5[ii01+plus_5][@timestamp_t]>=current_interval_30
					first=0
				end
				
				for tt in 0..plus_5
					hour_1h_n[-1][@high_b]=minute_5[ii01+tt][@high_b] if minute_5[ii01+tt][@high_b]>hour_1h_n[-1][@high_b]
					hour_1h_n[-1][@low_b]=minute_5[ii01+tt][@low_b] if minute_5[ii01+tt][@low_b]<hour_1h_n[-1][@low_b]
				end
				
				ii01+=plus_5	
				
				mid_value_1h = (current_open_1h+minute_5[ii01][@close_b])/2
				hour_1h_n[-1][@timestamp_t] = minute_5[ii01][@timestamp_t].deep_dup
				hour_1h_n[-1][@close_b] = minute_5[ii01][@close_b].deep_dup
				hour_1h_n[-1][@close_ask] = minute_5[ii01][@close_ask].deep_dup
				hour_1h_n[-1][@mid_b] = mid_value_1h
				hour_1h_n[-1][@candle_location_2_n]=(minute_5[ii01][@candle_location])  #the hour_1h_n contains both it's own candle_location and the 5th minute candle_location (candle_location_2)
				data_1h_n[-1] = minute_5[ii01][@close_b]#mid_value_1h
				data_3_n[ii3h] = minute_5[ii01][@close_b] # doing this because nil values get inserted randomly May10 (system bug)
				#############################______END TRIM AND UPDATE VALUES AND INTERVALS END_____#############################		
				

			

			#all_time.push([hour_1h_n[-1][@timestamp_t], hour_1h_n[-1][@close_b], hour_1h_n[-1][@close_ask], Time.at(timehere).day, Time.at(timehere).hour, Time.at(timehere).min])
			#p Time.at(timehere).year, Time.at(timehere).month, Time.at(timehere/1000).day, Time.at(timehere/1000).min, Time.at(timehere/1000).sec






				predicted_1_h,predicted_2_h,predicted_1_h2,predicted_2_h2 =0.0,0.0,0.0,0.0
				yule_hour_1.each_index { |x| predicted_1_h += yule_hour_1[x]*data_3_n[ii3h-x] }
				yule_hour_2.each_index { |x| predicted_2_h += yule_hour_2[x]*data_3_n[ii3h-x] }
				predicted_1_h2 += yule_hour_1[0]*predicted_1_h
				predicted_2_h2 += yule_hour_2[0]*predicted_1_h
				yule_hour_1.each_index { |x| predicted_1_h2 += yule_hour_1[x]*data_3_n[ii3h+1-x] if x>0 }
				yule_hour_2.each_index { |x| predicted_2_h2 += yule_hour_2[x]*data_3_n[ii3h+1-x] if x>0 }


				predicted_1_h-=data_3_n[ii3h]
				predicted_2_h-=data_3_n[ii3h]
				predicted_1_h2-=data_3_n[ii3h]
				predicted_2_h2-=data_3_n[ii3h]
				
				#### ~~~~~   GATHER VALUES ~~~~~ ####  	
							
				returned_values = [] 
				
				profit_buy,profit_24_buy, profit_48_buy, profit_72_buy=0,0,hour_1h_n[-1][@close_ask].deep_dup,hour_1h_n[-1][@timestamp_t].deep_dup  #let profit_48_buy to be closing ask and profit_72_buy be the timestamp
				buy_1h, buy_3h, buy_6h, buy_12h, buy_24h = minute_5[-13][@close_ask],minute_5[-37][@close_ask],minute_5[-73][@close_ask],minute_5[-145][@close_ask],minute_5[-289][@close_ask]
				##get values 3 hours, 12 hours, 24 hours, 48 hours, 72 hours ago
				current_val = hour_1h_n[-1][@close_b]				
				(buy_1h, buy_3h, buy_6h, buy_12h, buy_24h)=[buy_1h, buy_3h, buy_6h, buy_12h, buy_24h].map do |x|  
					x -= current_val
					x *=(-1*@@pip)
					x = x.round(1)
				end

				returned_values.push(profit_buy,profit_24_buy, profit_48_buy, profit_72_buy, 
				hour_1h_n[-1][@open_b],hour_1h_n[-1][@high_b],hour_1h_n[-1][@low_b],hour_1h_n[-1][@close_b],hour_1h_n[-1][@close_ask],hour_1h_n[-1][@candle_location],[],
				buy_1h, buy_3h, buy_6h, buy_12h, buy_24h)
			
				##pre values completed
				## add all calculations below
				regression_values = regression_addition(data_1h_n.dup, lag, lag2, x_axis_1h, x_axis_1h_2)
				hour_t = (hour_1h_n.deep_dup).transpose
				hour_time = hour_t[@timestamp_t]
				hour_val = hour_t[@close_b]

				peak_slope_return = [peak_1.peak_find_slope(hour_time.dup,hour_val.dup)].flatten
				peak_slope_return_2 = [peak_2.peak_find_slope(hour_time.dup,hour_val.dup)].flatten



				returned_values.push(*(regression_values.deep_dup))
				returned_values.push(*(peak_slope_return.deep_dup))
				returned_values.push(*(peak_slope_return_2.deep_dup))
				moving_avg_days.each do |x|
					total_hours_ma = x*24
					total_ma["ma_days_#{x}"] = moving_averages(data_1h_n.deep_dup,total_hours_ma)
					returned_values.push(*(total_ma["ma_days_#{x}"]).deep_dup)
				end
				#total_ma.each {| key, value | returned_values.push(*(value.deep_dup))} same as above

				hour_t.clear
				hour_time.clear
				hour_val.clear
	
				### clear values ###
				regression_values.clear
				#peak_slope_return.clear
				#peak_slope_return_2.clear
				total_ma.clear
				total_ma, regression_values,peak_slope_return, peak_slope_return_2 =nil, nil, nil, nil
				total_ma={}
				returned_values.push(predicted_1_h,predicted_2_h,predicted_1_h2,predicted_2_h2)
		
				all_values.push(returned_values.deep_dup)
				

				time_difference = hour_1h_n[-1][@timestamp_t]-all_values[update_final_ii][3]
				if  time_difference > timestamp_diff_epoch_held
					timehere = hour_1h_n[-1][@timestamp_t]/1000.to_i
					until (update_final_ii==all_values.count-1) || 
						(((Time.at(timehere).wday==1 && Time.at(timehere).hour>12) || Time.at(timehere).wday!=1) && (hour_1h_n[-1][@timestamp_t]-all_values[update_final_ii][3])<timestamp_diff_epoch_held) ||
						((Time.at(timehere).wday==1) && (Time.at(timehere).hour<12) && (time_difference< timestamp_diff_epoch_held+864000000)) 
							
							all_values[update_final_ii][1]=hour_1h_n[-1][@close_b]
							all_values[update_final_ii][0]=(hour_1h_n[-1][@close_b]-hour_1h_n[-1][@close_ask])*@@pip

							update_final_ii+=1	
					end
				end
				##################### _______________ RUN BACKTEST ______________ #########################  


				
				##################### _______________ DECISION MECHANISM ______________ #########################
				
				#market_decision(decision_mechanism, returned_values)
				decision_mechanism=[]
				prev_analytics = []#market_decision(prev_analytics.deep_dup, currency, decision_mechanism.dup, returned_values, hour_1h_n.deep_dup, hours_held=hours_held)
			
				#new_minute_5.push(hour_1h_n[-1].deep_dup)
		#####################
			
			end #minute_5[ii01][timestamp_t]<current_interval

		
		ii01+=1 
		#ii+=1 
		hour_1.shift
		hour_1h_n.shift
		data_1h.shift
		data_1h_n.shift
		current_ii+=1

			
		end #ii<hour_1.count  #here's where the action ends
			





			temp_file = @ruby_file + "/delete_this.csv"
			CSV.open(temp_file, 'wb' ) do |writer| 
				all_time.each do |d|
					writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7]]
				end
			end





			
			
	#hour_1_ori.clear
	#hour_1h_n.clear
	#hour_1.clear
	#minute_5.clear
	return 0
	end

	
	def market_decision(prev_analytics, currency, decision_tree, current_values, hour_v, hours_held)
	

		decision_choice_up,total_decision,total_prob = FALSE,0,0
		decision_choice_down = FALSE
		decision_choice_up2, decision_choice_down2 = FALSE, FALSE 
		long, short= "Long", "Short"
		decision_prob_up, decision_prob_down=0,0
		current_values2 = current_value_fix_nbayes(current_values)
		if @nbayes_up_yes 
			result = @nbayes_up.classify(current_values2)
			curr_result = result.max_class
			curr_prob = result[result.max_class]
			long_class_prob, short_class_prob, neutral_class_prob = result[long], result[short], result["NA"]
			puts "Decision: #{curr_result} |	Prob long: #{long_class_prob.round(3)}	#{curr_result==long}	| Prob short: #{short_class_prob.round(3)}" if (curr_prob>0.346 && curr_result == long && short_class_prob<0.328)  || @first_array #if curr_result != "NA"
				if @first_array 
					print current_values2 
					puts " " 
					@first_array=FALSE 
				end
			
			decision_choice_up=TRUE if (curr_prob>0.346 && curr_result == long && short_class_prob<0.328) 
			decision_choice_down2 = TRUE if (curr_prob>0.346 && curr_result == short && long_class_prob<0.328)
			decision_prob_up = curr_prob
		end
		if @nbayes_down_yes
			result = @nbayes_down.classify(current_values2)
			curr_result = result.max_class
			curr_prob = result[result.max_class]
			long_class_prob, short_class_prob, neutral_class_prob = result[long], result[short], result["NA"]
				puts "Decision: #{curr_result} |	Prob short: #{short_class_prob.round(3)} #{curr_result==short}	| Prob long: #{long_class_prob.round(3)}	#{curr_result==long}" if short_class_prob>0.346 || @first_array #if curr_result != "NA"
				if @first_array 
					print current_values2[0..12]  
					puts " " 
					@first_array=FALSE 
				end
			decision_choice_up2=TRUE if (curr_prob>0.346 && curr_result == long && short_class_prob<0.328) 
			decision_choice_down = TRUE if (curr_prob>0.346 && curr_result == short && long_class_prob<0.328)
			decision_prob_down = curr_prob
		end
		
		#decision_tree.each do |dec|
		#	dec_eval = eval(dec[0])	
		#	if dec_eval && dec[1]>0.6 && dec[2]>50
		#		total_prob += dec[1]
		#		total_decision +=1
		#	end	
		#end
		
		#puts "Trade Made #{total_prob} with #{total_decision}" if (total_decision>=@total_decision_needed)
		#decision_choice_up = TRUE if total_decision>=@total_decision_needed
			
		
		#prev_analytics = read_analytics_live(currency)  # commented since February
		changes_to_prev_analytics = FALSE
		current_time = hour_v[-1][@timestamp_t]
			pa_start_utc,pa_end_utc,pa_trend,pa_start_price,pa_end_price,pa_highest_price,pa_lowest_price,pa_correct_wrong,pa_closed_open,pa_confidence=0,1,2,3,4,5,6,7,8,9
			pa_end_30_utc,pa_end_30_price, pa_highest_30_price, pa_lowest_30_price, pa_correct_wrong_30 = 10,11,12,13,14
			pa_end_60_utc,pa_end_60_price, pa_highest_60_price, pa_lowest_60_price, pa_correct_wrong_60 = 15,16,17,18,19
			pa_end_120_utc,pa_end_120_price, pa_highest_120_price, pa_lowest_120_price, pa_correct_wrong_120 = 20,21,22,23,24
			pa_period_adjust,pa_period_adjust_2,pa_period_adjust_3,pa_period_adjust_4=25,26,27,28

		
		
		#update prev_analytics
		if prev_analytics[-1][pa_closed_open]=="open" #  intrend
			changes_to_prev_analytics=TRUE
			opened_trades = []
			prev_analytics.each_with_index {|row, index| opened_trades.push(index) if row[pa_closed_open]=="open"}
			cc=0
			while cc<opened_trades.count
				pa_cc = opened_trades[cc]
				
				##----- Update trades ----##
				prev_analytics[pa_cc][pa_end_utc]= current_time
				start_time = prev_analytics[pa_cc][pa_start_utc]
				prev_analytics[pa_cc][pa_highest_price] = [hour_v[-1][@high_b],prev_analytics[pa_cc][pa_highest_price]].max
				prev_analytics[pa_cc][pa_lowest_price] = [hour_v[-1][@low_b],prev_analytics[pa_cc][pa_lowest_price]].min
				prev_analytics[pa_cc][pa_end_price] = prev_analytics[pa_cc][pa_trend]=="Up trend" ? hour_v[-1][@close_b] : hour_v[-1][@close_ask]
				difference = ((prev_analytics[pa_cc][pa_end_price]-prev_analytics[pa_cc][pa_start_price])*@@pip).round(4)
				if prev_analytics[pa_cc][pa_trend]=="Up trend"
					prev_analytics[pa_cc][pa_correct_wrong]= difference>0 ? @green : @red	
				elsif prev_analytics[pa_cc][pa_trend]=="Down trend"
					prev_analytics[pa_cc][pa_correct_wrong]= difference<0 ? @green : @red	
				end
				##----- Update trades ----##
				
				#close trades ######  might need to separate the close trades as it's going to be more complicated in the future
				time_adjust = remove_weekend_jumps(prev_analytics[pa_cc][pa_start_utc], hour_v)				
				period = ((current_time - prev_analytics[pa_cc][pa_start_utc]) - time_adjust)/(@time_convert*1000) #time_convert is 3600 = 1 minute, *1000 because of milliseconds.
				if period>=hours_held # 12 hours
					prev_analytics[pa_cc][pa_closed_open]="closed"	
				end
				#close trades end #######
				
			cc+=1
			end #cc	
		end
		
		decision_enter=TRUE if (decision_choice_up || decision_choice_down)
		decision_enter=FALSE if (decision_choice_up && decision_choice_down)
		
		
		
		if decision_enter
			#decision_prob = (total_prob/total_decision)
			changes_to_prev_analytics=TRUE
			if decision_choice_up
				prev_analytics.push([current_time,current_time,"Up trend",hour_v[-1][@close_ask],hour_v[-1][@close_b],hour_v[-1][@high_b],hour_v[-1][@low_b],@red,"open",decision_prob_up,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])	
			elsif decision_choice_down
				prev_analytics.push([current_time,current_time,"Down trend",hour_v[-1][@close_b],hour_v[-1][@close_ask],hour_v[-1][@high_b],hour_v[-1][@low_b],@red,"open",decision_prob_down,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0])	
			end
			prev_analytics[-1][pa_trend]=="Up trend" ? buy_sell=1 : buy_sell=-1
			prev_analytics.delete_at(0) if prev_analytics[0][pa_trend]=="NEW"
			puts "ENTRY COUNT : #{prev_analytics.count}"
		end
			
		#car2=Report_trend.new
		#car2.gone_out_of_trend(current,buy_sell,start_time,current_time,prev_analytics[-1][pa_start_price],prev_analytics[-1][pa_end_120_price],@pip)
		#if changes_to_prev_analytics
			#path_loc = "#{@save_live_analytics}/#{currency}/#{@version}_backtest_analytics.csv"
			#CSV.open(path_loc, 'wb' ) do |writer|  
			#	prev_analytics.each do |d|
			#		writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29],d[30],d[31],d[32],d[33],d[34]]
			#	end
			#end
		#end
	return prev_analytics.dup
	end 
	
	
	def regression_addition(hour_mid,  lag, lag2, x_axis, x_axis_2)
	total_reg = lag.count
	#total_reg is the total number of regressions
	#lag must be an array that corresponds to the total number of regressions
	if lag2.count!=total_reg || x_axis.count!=total_reg || x_axis_2.count!=total_reg
		puts "TOTAL COUNT NOT SAME"
		stop
	end
		longest_lag = lag.max
		longest_lag2 = lag2.max
		json,data_2=[],[]
		hour_data_count = hour_mid.count
		do_here=hour_data_count-(longest_lag2+1) # don't need to process all the values, just need to get a few slope values and some extra to get the 2nd derivative) 
		t_json, t_data_2=[],[]


		i=do_here 
		while i<hour_data_count
			t_json, t_data_2=[],[]
			
			lag.each_index do |ll|
				intercept, regression_slope, cov00, cov01, cov11, chisq = linearregression(x_axis[ll], hour_mid[i-lag[ll]..i])
				intercept_diff = intercept-hour_mid[i]
				errors=chisq #subject to change between cov00, cov01, cov11
				#estimated_value = intercept+(regression_slope*(x_axis[-1].to_f))
				#est_diff_bid_slope = hour_data[i][@close_b]-estimated_value
				#est_diff_ask_slope = hour_data[i][@close_ask]-estimated_value
				
				estimated_value = regression_slope/cov00  #need to check values are doable
				est_diff_bid_slope = regression_slope/cov01
				est_diff_ask_slope = regression_slope/cov11
				
				t_json.push(regression_slope,errors,intercept_diff,est_diff_bid_slope,est_diff_ask_slope,0.0,0.0,(regression_slope/chisq))				
				t_data_2.push(regression_slope)
			end
		json.push(t_json.deep_dup)
		data_2.push(t_data_2.deep_dup)
		t_json, t_data_2 = nil, nil
		i+=1
		end
		hour_mid.clear
		

		data_2_t = data_2.transpose
		i2=data_2.count-1 #just want the final value for second derivative
		#I would just need the final second derivative value
		lag2.each_index do |x|
			intercept2, regression_slope2, cov00_2, cov01_2, cov11_2, chisq_2 = linearregression(x_axis_2[x], data_2_t[x][i2-lag2[x]..i2]) 
			pos_x = (x+1)*8
			json[-1][(pos_x-3)] = regression_slope2
			json[-1][(pos_x-2)]= chisq_2
			#json[-1][(pos_x-1)]= cov01_2
		end
			
		return_json_value = json[-1]
		
	return return_json_value


	end  #end def periodic_movement
	

	def read_data(path) 
		data=[]
		mid_data=[]
		File.open(path) do |f|
	  		FastCSV.raw_parse(f) do |content|
				real1 = content[0].to_i   	#timestamp
				real7 = content[6].to_f		#mid b
				real8 = content[7].to_f		#open b
				real9 = content[8].to_f		#high b
				real10 = content[9].to_f	#low b
				real11 = content[10].to_f	#close b
				real12 = content[11].to_f	#close ask
			data.push([real1,real7,real8,real9,real10,real11,real12])
			mid_data.push(real11)
			end
		end
		data.slice!(0)
		mid_data.slice!(0)
		return data,mid_data
	end



	def read_long_hours(path) 
		data=[]
		File.open(path) do |f|
	  		FastCSV.raw_parse(f) do |content|
				real1 = content[0].to_i   	#timestamp
				real11 = content[10].to_f	#close b
				data.push([real1,real11])
			end
		end
		data.slice!(0)

		return data.transpose
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

	def decimals(a)
		num = 0
		while(a != a.to_i)
			num+= 1
			a*= 10
			a = a.round(8)
		end
		num=10**num
		return num
	end


	def pip_value(curr)
		case curr
			when "AUDUSD","EURAUD","EURCAD","EURGBP","EURUSD","GBPUSD","NZDUSD","USDCAD","USDCHF","USDCNH","USDRUB" then pip_v=10000.0
			when "CADJPY","GBPJPY","USDJPY","XAGUSD" then pip_v=1000.0
			when "EURJPY","EURRUB","USDXVN","XAUUSD" then pip_v=100.0
			when "NDX","SPX","UK100" then pip_v=10.0
			when "WS30" then pip_v=1.0
		end
		return pip_v
	end

	def track_progress_1(time_check)  # Just to track progress
		@month_here = Time.at(time_check/1000).month
		puts "..#{@month_here} " 
	end

	def track_progress_2(time_check) # Just to track progress
		if Time.at(time_check/1000).month!=@month_here
			@month_here = Time.at(time_check/1000).month
			puts "..#{@month_here} . "
		end
	end

	def moving_averages(dataset,average_movement=240) #average movement is the in hours, so 10 day = 24 hours *10=240. # we use mid values here
		total_columns = 16 #the total number of columns noted here
		#@m_expected_v,@m_ob_ex_diff, @m_ob_ex_avg, @m_ob_ex_max, @m_sum_pos, @m_sum_neg, @m_std_dev = 0,1,2,3,4,5,6
		#@m_diff_more_stddev_two_times, @m_diff_more_stddev_one_times, @m_diff_more_stddev_half_times, @m_diff_less_stddev_tenth =7,8,9,10
		#@m_current_pos, @m_current_neg = 11,12
		#@m_recent_24_hours_pos_neg, @m_recent_12_hours_pos_neg, @m_curr_less_avg = 13, 14, 15
		cross_up_down, cross_index = 0,1  
		up_cross, down_cross = "up_cross", "down_cross"
		peak_valley_value, peak_valley_index = 0,1
		ma_result = []
		dd=average_movement-1
		ma_set =Array.new(average_movement-1){Array.new(2,0)} #this creates array within array. The beginning zeroes is in order for ma_set to be same size as dataset
		while dd<dataset.count
			dd_start = dd-average_movement+1
			ma_value = dataset[dd_start..dd].avg #ArrayMath.new.sum(dataset[dd_start..dd])/ average_movement.to_f
			ma_observe_expect_diff = dataset[dd]-ma_value  #differece is observed - expected
			ma_set.push([ma_value.round(8),ma_observe_expect_diff.round(8)])
		dd+=1
		end

		dataset.clear
		#no need to create index / candle location values because no trimming performed
		#now to create meta-analysis
		ma_set_count = ma_set.count
			#this will acquire all the changes in up down crossing cycle
		peak_finding_interval = 8
		ma_tt_start =average_movement+peak_finding_interval	
		first_crossed_list = ma_set[(average_movement+2)][@m_ob_ex_diff]>=0 ? [up_cross,ma_tt_start] : [down_cross,ma_tt_start] 				#average_movement+2 to avoid the zeroes at the front
		time_since_last_crossed =Array.new(1){Array.new(first_crossed_list)}	#we can check up to 2 previous histories of crossing the positive negative boundary. 
		#Will only include 1 previous histories for now because we're only processing a limited number of days #once we increase the number of days processed, we can increase the array beyond 2 recent history numbers
		time_since_peak =Array.new(1){Array.new([ma_set[average_movement+2][@m_expected_v],ma_tt_start])}
		time_since_valley =Array.new(1){Array.new([ma_set[average_movement+2][@m_expected_v],ma_tt_start])}
		temp_ma_set_0 = (ma_set.deep_dup.transpose)[@m_expected_v]
		#the peak finding is performed by checking if the center value is lower/higher between the start point and end point. Then we search for a min or max value
		(ma_tt_start..ma_set_count-peak_finding_interval-1).step(peak_finding_interval) do |ma_tt|	
			previous_tt = (ma_tt-peak_finding_interval)
			after_tt = (ma_tt+peak_finding_interval)
			if temp_ma_set_0[previous_tt]<temp_ma_set_0[ma_tt] && temp_ma_set_0[after_tt]<temp_ma_set_0[ma_tt]
				index_ma_tt_peak = previous_tt+ (temp_ma_set_0[previous_tt..after_tt].rindex(temp_ma_set_0[previous_tt..after_tt].max)) #ma_set_count minus is used to get the distance from current point 
				time_since_peak.push([temp_ma_set_0[index_ma_tt_peak],index_ma_tt_peak]) if time_since_peak[-1][peak_valley_index]!=index_ma_tt_peak
			elsif temp_ma_set_0[previous_tt]>temp_ma_set_0[ma_tt] && temp_ma_set_0[after_tt]>temp_ma_set_0[ma_tt]
				index_ma_tt_valley = previous_tt+ (temp_ma_set_0[previous_tt..after_tt].rindex(temp_ma_set_0[previous_tt..after_tt].min))
				time_since_valley.push([temp_ma_set_0[index_ma_tt_valley],index_ma_tt_valley]) if time_since_valley[-1][peak_valley_index]!=index_ma_tt_valley
			end
			#to find crossover
			if ma_set[ma_tt][@m_ob_ex_diff]>0 && time_since_last_crossed[-1][cross_up_down]==down_cross
				time_since_last_crossed.push([up_cross,ma_tt]) 
			elsif ma_set[ma_tt][@m_ob_ex_diff]<0 && time_since_last_crossed[-1][cross_up_down]==up_cross
				time_since_last_crossed.push([down_cross,ma_tt])
			end
		end			# end for loopwhenver ma_set switches from positive to negative, and find peaks. 
		
		time_since_peak.slice!(0) if time_since_peak.count>=3 
		time_since_valley.slice!(0) if time_since_valley.count>=3
		time_since_last_crossed.slice!(0) if time_since_last_crossed.count>=3
		peak_count, valley_count, cross_count = time_since_peak.count, time_since_valley.count, time_since_last_crossed.count
		span_peak, span_valley, span_cross = 0.0, 0.0, 0.0
		(0..peak_count-2).each{|x| span_peak+=(time_since_peak[x][peak_valley_index]-time_since_peak[x+1][peak_valley_index]).abs}
		(0..valley_count-2).each{|x| span_valley+=(time_since_valley[x][peak_valley_index]-time_since_valley[x+1][peak_valley_index]).abs}
		(0..cross_count-2).each{|x| span_cross+=(time_since_last_crossed[x][cross_index]-time_since_last_crossed[x+1][cross_index]).abs}
		span_peak/=(peak_count-1) if peak_count!=1
		span_valley/=(valley_count-1) if valley_count!=1
		span_cross/=(cross_count-1) if cross_count!=1
		if span_peak<=0.1 && peak_count==1
			max_p = temp_ma_set_0.max
			ind_p = temp_ma_set_0.rindex(max_p)
			time_since_peak.push([max_p,ind_p])
			span_peak = (ma_set_count-ind_p).to_f
		end
		if span_valley<=0.1 && valley_count==1
			min_v = temp_ma_set_0.min
			ind_v = temp_ma_set_0.rindex(min_v)
			time_since_valley.push([min_v,ind_v])
			span_valley = (ma_set_count-ind_v).to_f
		end
		span_cross=ma_set_count if time_since_last_crossed.count==1
		peak_count, valley_count, cross_count, max_p, ind_p,min_v,ind_v,temp_ma_set_0 = nil,nil,nil,nil,nil,nil,nil,nil

		ma_set.each {|x|(total_columns-2).times{x.push(0)}} #it's important to include the columns before transposing because the first (average_movement)total columns are 0. total_columns-2 is because the first two are already included, eg m_expected_v,@m_ob_ex_diff
		recent_24_hours, recent_12_hours = 24.0, 12.0
		dd1=(ma_set.count-1) # we only need the final value for backtest. For compile_analytics, use -->	# dd1=average_movement-1
		temp_ma_set=ma_set.transpose
		while dd1<ma_set_count	
			dd_start = dd1-average_movement+1
			ma_avg = temp_ma_set[@m_ob_ex_diff][dd_start..dd1].avg #ArrayMath.new.sum(temp_ma_set[@m_ob_ex_diff][dd_start..dd1])/average_movement.to_f   #ma_set[dd_start..dd1].inject(0.0) { |sum, el| sum + el[@m_ob_ex_diff] } / average_movement  #calculates average difference between observed and expected
			ma_max_val = temp_ma_set[@m_expected_v][dd_start..dd1].max
			ma_min_val = temp_ma_set[@m_expected_v][dd_start..dd1].min
			ma_max_index = dd_start + temp_ma_set[@m_expected_v][dd_start..dd1].rindex(ma_max_val)
			ma_min_index = dd_start + temp_ma_set[@m_expected_v][dd_start..dd1].rindex(ma_min_val)
			ma_max = ma_max_val-temp_ma_set[@m_expected_v][dd1] #calculates maximum difference between observed and expected
			ma_min = ma_min_val-temp_ma_set[@m_expected_v][dd1] ## NEED TO ADD THIS IN
			
			#since_max_val = dd1-ma_max_index
			#since_min_val = dd1-ma_min_index
			
			#ma_sum_pos = ma_avg >= 0 ? 1 : 0 #sum pos and sum neg no longer necessary, just use ma_avg
			#ma_sum_neg = ma_avg < 0 ? 1 : 0  #sum pos and sum neg no longer necessary, just use ma_avg
			
			ma_variance = ma_set[dd_start..dd1].inject(0.0) {|accum, i| accum +(i[@m_ob_ex_diff]-ma_avg)**2 }
			ma_variance/= average_movement
			ma_std_dev = Math.sqrt(ma_variance)
			proportion_ex_diff_to_std_dev = ((ma_set[dd1][@m_ob_ex_diff]-ma_std_dev)/ma_std_dev).round(8) #use the proportion instead of the plain std value
			
			since_span_peak_p = span_peak>0 ? ((dd1-time_since_peak[-1][peak_valley_index]).to_f/span_peak).round(4) : 0
			since_span_valley_p = span_valley>0 ? ((dd1-time_since_valley[-1][peak_valley_index]).to_f/span_valley).round(4) : 0
			since_span_crossed_p = span_cross>0 ? ((dd1-time_since_last_crossed[-1][cross_index]).to_f/span_cross).round(4) : 0
			
			#ma_diff_more_stddev_two_times = (ma_set[dd1][@m_ob_ex_diff].abs) >=(ma_std_dev*2) ? 1 : 0  #to be removed, just use m_ob_ex_diff
			#ma_diff_more_stddev_one_times = ((ma_set[dd1][@m_ob_ex_diff].abs) >=(ma_std_dev*1) && (ma_set[dd1][@m_ob_ex_diff].abs) <(ma_std_dev*2)) ? 1 : 0 #to be removed, just use m_ob_ex_diff
			#ma_diff_more_stddev_half_times = ((ma_set[dd1][@m_ob_ex_diff].abs)>=(ma_std_dev*0.5) && (ma_set[dd1][@m_ob_ex_diff].abs) <(ma_std_dev*1)) ? 1 : 0 #to be removed, just use m_ob_ex_diff
			#ma_diff_less_stddev_tenth = (ma_set[dd1][@m_ob_ex_diff].abs) < (ma_std_dev*0.1) ? 1 : 0 #to be removed, just use m_ob_ex_diff
			
			#ma_current_pos = ma_set[dd1][@m_ob_ex_diff] >= 0 ? 1 : 0	# I want to remove this to include time
			#ma_current_neg = ma_set[dd1][@m_ob_ex_diff] < 0 ? 1 : 0		# I want to remove this to include time
			
			#time since last crossed
			
			ma_sum_recent_max = temp_ma_set[@m_ob_ex_diff][ma_max_index..dd1].sum #ArrayMath.new.sum(temp_ma_set[@m_ob_ex_diff][ma_max_index..dd1])
			ma_sum_recent_min = temp_ma_set[@m_ob_ex_diff][ma_min_index..dd1].sum #ArrayMath.new.sum(temp_ma_set[@m_ob_ex_diff][ma_min_index..dd1])
				
			dd_recent_24_hours, dd_recent_12_hours = (dd1-recent_24_hours+1), (dd1-recent_12_hours+1)
			#ma_avg_recent_24_hours = ma_set[dd_recent_24_hours..dd1].inject(0.0) { |sum, el| sum + el[@m_ob_ex_diff] } / recent_24_hours
			#ma_avg_recent_12_hours = ma_set[dd_recent_12_hours..dd1].inject(0.0) { |sum, el| sum + el[@m_ob_ex_diff] } / recent_12_hours
			ma_avg_recent_24_hours = temp_ma_set[@m_ob_ex_diff][dd_recent_24_hours..dd1].avg #ArrayMath.new.sum(temp_ma_set[@m_ob_ex_diff][dd_recent_24_hours..dd1]) / recent_24_hours.to_f
			ma_avg_recent_12_hours = temp_ma_set[@m_ob_ex_diff][dd_recent_12_hours..dd1].avg #ArrayMath.new.sum(temp_ma_set[@m_ob_ex_diff][dd_recent_12_hours..dd1]) / recent_12_hours.to_f
			
			index_recent_cross = time_since_last_crossed[-1][cross_index]
			index_2nd_recent_cross = time_since_last_crossed.count>1 ? time_since_last_crossed[-2][cross_index] : index_recent_cross
			
			#ma_sum_recent_cross = temp_ma_set[@m_ob_ex_diff][index_recent_cross..dd1].inject(:+)
			#ma_sum_2nd_recent_cross = temp_ma_set[@m_ob_ex_diff][index_2nd_recent_cross..dd1].inject(:+)
	
			#ma_recent_24_hours_pos_neg = ma_avg_recent_24_hours > 0 ? 1 : -1 #to be removed just use original values
			#ma_recent_12_hours_pos_neg = ma_avg_recent_12_hours > 0 ? 1 : -1 #to be removed just use original values
			
			#ma_diff_avg_pos_only = temp_ma_set[@m_ob_ex_diff][dd_start..dd1].select {|c| c > 0 }.inject(0.0,&:+)/(temp_ma_set[@m_ob_ex_diff][dd_start..dd1].count{|x| x> 0})
			#ma_diff_avg_neg_only = (temp_ma_set[@m_ob_ex_diff][dd_start..dd1].select {|c| c < 0 }.inject(0.0,&:+)).abs/(temp_ma_set[@m_ob_ex_diff][dd_start..dd1].count{|x| x< 0})
		
			#	ma_curr_less_avg = temp_ma_set[@m_ob_ex_diff][dd1] < ma_diff_avg_pos_only ? 1 : 0 if temp_ma_set[@m_ob_ex_diff][dd1] >= 0 #if the current difference is less than the average of its category, that means it is susceptible to changes
			#	ma_curr_less_avg = temp_ma_set[@m_ob_ex_diff][dd1] < ma_diff_avg_neg_only ? 1 : 0 if temp_ma_set[@m_ob_ex_diff][dd1] < 0
			
			ma_set[dd1][@m_ob_ex_avg],ma_set[dd1][@m_ob_ex_max] =  ma_avg.round(8), ma_max.round(8)
			ma_set[dd1][@m_sum_pos], ma_set[dd1][@m_sum_neg], ma_set[dd1][@m_std_dev] = (temp_ma_set[@m_expected_v][dd1]-time_since_peak[-1][peak_valley_value]), (temp_ma_set[@m_expected_v][dd1]-time_since_peak[-2][peak_valley_value]), proportion_ex_diff_to_std_dev
			ma_set[dd1][@m_diff_more_stddev_two_times], ma_set[dd1][@m_diff_more_stddev_one_times] =temp_ma_set[@m_expected_v][dd1]-time_since_valley[-1][peak_valley_value],temp_ma_set[@m_expected_v][dd1]-time_since_valley[-2][peak_valley_value]
			ma_set[dd1][@m_diff_more_stddev_half_times], ma_set[dd1][@m_diff_less_stddev_tenth] = since_span_peak_p, since_span_valley_p
			
			#ma_set[dd1][@m_sum_pos], ma_set[dd1][@m_sum_neg], ma_set[dd1][@m_std_dev] = ma_sum_pos, ma_sum_neg, ma_std_dev.round(8)
			#ma_set[dd1][@m_diff_more_stddev_two_times], ma_set[dd1][@m_diff_more_stddev_one_times]  = ma_diff_more_stddev_two_times, ma_diff_more_stddev_one_times
			#ma_set[dd1][@m_diff_more_stddev_half_times], ma_set[dd1][@m_diff_less_stddev_tenth] = ma_diff_more_stddev_half_times, ma_diff_less_stddev_tenth
			#ma_set[dd1][@m_current_pos], ma_set[dd1][@m_current_neg] = ma_current_pos, ma_current_neg
			#ma_set[dd1][@m_recent_24_hours_pos_neg], ma_set[dd1][@m_recent_12_hours_pos_neg] = ma_recent_24_hours_pos_neg, ma_recent_12_hours_pos_neg
			#ma_set[dd1][@m_curr_less_avg] = ma_curr_less_avg
			
			ma_set[dd1][@m_current_pos], ma_set[dd1][@m_current_neg] = ma_sum_recent_max, ma_sum_recent_min
			ma_set[dd1][@m_recent_24_hours_pos_neg], ma_set[dd1][@m_recent_12_hours_pos_neg] = ma_avg_recent_24_hours,ma_avg_recent_12_hours #ma_sum_recent_cross, ma_sum_2nd_recent_cross
			ma_set[dd1][@m_curr_less_avg] = since_span_crossed_p
			
			dd1+=1
		end

		return  ma_set[-1] #for backtest, we only return the last value ma_set[-1], all other values are unecessary    ma_set for compile analytics
		
		

	end

	def moving_average_diff(val1, val2)
		return 0
	end
	
	
	
	def space(spacing=2)
	spacing.times{puts "	"}
	end

	def find_epoch_days_ago(epoch_today, total_days=90)
		epoch_previous = ((epoch_today/1000.0).floor) -(24*60*60*total_days)
		epoch_date = Time.at(epoch_previous)
		return epoch_date.year, epoch_date.month, epoch_date.day
	end
	
	def read_tree_results(filename)
		target_data, variable_data, decision_data=[], [], []
		target, variable_start, variable_end=TRUE, FALSE, FALSE
		csv_contents = CSV.parse(File.read(filename, converters: :numeric))
		csv_contents.each do |content|
			r1 = content[0]   	#Variables
			r2 = content[1]		#Variables
			r3 = content[2].to_f		#Expected
			r4 = content[3].to_i		#Total expected
			
			if target	
				target_data.push([r1,r2])
				if r1.include? "Variable Start"
					target, variable_start, variable_end=FALSE, TRUE, FALSE
					target_data.delete_at(-1)
				end			
			elsif variable_start
				variable_data.push([r2])
				if r1.include? "Variable End"
					target, variable_start, variable_end=FALSE, FALSE, TRUE
					variable_data.delete_at(-1)
					end
			elsif variable_end
				decision_data.push([r1.downcase,r3,r4])
			end
			
		end

		return variable_data, decision_data	
	end
	
	def write_currency(currency)
		CSV.open(@currency_save_file, 'wb' ) do |writer|  
			writer << [currency]
			writer << [@store_analytics_file]
			writer << [@output_decision_file]
		end
	end 
	
	def week_check(timestamp)
	weekdate = (Time.at(timestamp/1000).utc).to_date
	week_now = weekdate.cweek
		if week_now!=@current_week
			@current_week=week_now
			@current_half_week_check=TRUE
			return TRUE
		else
			return FALSE
		end
	end
	
	def half_week_check(timestamp)
	weekdate = (Time.at(timestamp/1000).utc).to_date
	wednesday_now = (weekdate.cwday == 4)
		if wednesday_now && @current_half_week_check 	#redo trade results on thursday
			@current_half_week_check=FALSE
			return TRUE
		else
			return FALSE
		end
	end
	
	def run_R_analytics
		File.delete(@r_file_signal) if File.directory?(@r_file_signal) 
		puts "analytics time"
		#`R CMD BATCH /home/ruby/Nov_15/machine_learn/dec_tree_backtest_v11.R`
		`Rscript "C:/Users/J Wong/Documents/R/dec_tree_backtest_v12_3.R"`
		#`R CMD BATCH "C:/Users/J Wong/Documents/R/dec_tree_backtest_v12.R"`
		until File.exists?(@r_file_signal) 
			sleep(1)
			puts "still sleeping"
		end
		
		return 0
	end
	
	def compile_R_analytcs(folder_location, mininum_pass=0.6)
		all_decision_above_min = []
		dec_eval, dec_prob, dec_tot = 0,1,2
		Dir.open(folder_location).each do |filename|
			next if File.directory? filename
			puts filename
			variable_data, decision_data = read_tree_results("#{folder_location}/#{filename}")
			decision_data.each do |dec|
				all_decision_above_min.push(dec) if (dec[dec_prob]>mininum_pass && dec[dec_tot]>50)
			end
		decision_data.clear
		end
		
		CSV.open(@final_output_decision_file, 'wb' ) do |writer|  
			all_decision_above_min.each do |d|
				writer << [d[0],d[1],d[2]]
			end
		end
	return 0
	end
	
	def read_final_decision_file
	decision_data=[]
		csv_contents = CSV.parse(File.read(@final_output_decision_file, converters: :numeric))
		csv_contents.each do |content|
			r1 = content[0]   	#eval
			r2 = content[1].to_f		#prob
			r3 = content[2].to_i		#total observations
			decision_data.push([r1,r2,r3])
		end
	return decision_data
	end
	
	def read_analytics_live(current)
		path_loc = "#{@save_live_analytics}/#{current}/#{@version}_backtest_analytics.csv"
		data=[]
		File.open(path_loc) do |f|
      		FastCSV.raw_parse(f) do |content|
			real1 = content[0].to_i		#start utc	
			real2 = content[1].to_i		#end utc
			real3 = content[2]			#Trend
			real4 = content[3].to_f		#Start price
			real5 = content[4].to_f		#End price
			real6 = content[5].to_f 	#Highest price
			real7 = content[6].to_f		#Lowest price
			real8 = content[7]			#Correct/wrong
			real9 = content[8]			#closed or open
			real10 = content[9].to_f 	#Confidence 
			real11 = content[10].to_i 	#end utc 2
			real12 = content[11].to_f 	#End price 2
			real13 = content[12].to_f 	#Highest price 2
			real14 = content[13].to_f 	#Lowest price 2
			real15 = content[14]	 	#Correct/wrong2 
			real16 = content[15].to_i 	#end utc 3
			real17 = content[16].to_f 	#End price 3
			real18 = content[17].to_f 	#Highest price 3
			real19 = content[18].to_f 	#Lowest price 3
			real20 = content[19]	 	#Correct/wrong3 
			real21 = content[20].to_i 	#end utc 4
			real22 = content[21].to_f 	#End price 4
			real23 = content[22].to_f 	#Highest price 4
			real24 = content[23].to_f 	#Lowest price 4
			real25 = content[24]	 	#Correct/wrong4 
			real26 = content[25].to_f 	# period correction
			real27 = content[26].to_f 	# period correction2
			real28 = content[27].to_f 	# period correction3
			real29 = content[28].to_f 	# period correction4
			real30 = content[29].to_i 	#index
			data.push([real1,real2,real3,real4,real5,real6,real7,real8,real9,real10,real11,real12,real13,real14,real15,real16,real17,real18,real19,real20,real21,real22,real23,real24,real25,real26,real27,real28,real29,real30])
		end
		end
		data.slice!(0)
		return data
	end

	def write_analytics_live(current, prev_analytics)
		path_loc = "#{@save_live_analytics}/#{current}/#{@version}_backtest_analytics.csv"
		prev_analytics.insert(0,["#{current}Start Time","End Time","Trend","Start Price","End Price","Highest Difference","Lowest Difference","Correct/Wrong","Open/Closed","Confidence"])
		CSV.open(path_loc, 'wb' ) do |writer|  
			prev_analytics.each do |d|
				writer << [d[0],d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],d[11],d[12],d[13],d[14],d[15],d[16],d[17],d[18],d[19],d[20],d[21],d[22],d[23],d[24],d[25],d[26],d[27],d[28],d[29]] #,d[30],d[31],d[32],d[33],d[34]
			end
		end
	end
	
	def remove_weekend_jumps(pa_time, hour_v1)
		total_remove, k=0,0
		k+=1 until hour_v1[k][@timestamp_t]>pa_time  #this finds pa_time's location in hour_v1. This will only work if the trade is below 20 days

		
		while k<hour_v1.count
			time_diff = hour_v1[k][@timestamp_t]-hour_v1[k-1][@timestamp_t]
			if time_diff>5400000 # 1.5 hours 
				total_remove+=time_diff
			end
			k+=1
		end
		
		return total_remove
	end
	
	def V14_nbayes_run_inline(dataset)
		#load_nbayes =  NBayes::Base.from(file)
		avg_max_array =  Array.new(total_columns) { Array.new(2,0) }  #[0,0],[0,0] ...
		columns_wanted = [@j_slope_7,@j_2_slope_8,@j_intercept_10,@jest_diff_bid_slope_11,@jest_diff_ask_slope_12, 
			@jbuy_1h_ago_13,@jbuy_3h_ago_14,@jbuy_6h_ago_15,@jbuy_12h_ago_16,@jbuy_24h_ago_17,
			@j_m_ob_ex_diff_19, @j_m_ob_ex_avg_20, @j_m_ob_ex_max_21,@j_m_std_dev_24,   #j_m_expected_v_18,
			@j_m_2_ob_ex_diff_35, @j_m_2_ob_ex_avg_36, @j_m_2_ob_ex_max_37,@j_m_2_std_dev_40]  #j_m_2_expected_v_34,

		dataset.each do |x|
			columns_wanted.each do |y|
				avg_max_array[y][aver]+=x[y]
				avg_max_array[y][maxi]= [avg_max_array[y][maxi],(x[y].abs)].max
			end
		end

		columns_wanted.each do |y2|
			avg_max_array[y2][aver]/=total_rows
			avg_max_array[y2][maxi]-=avg_max_array[y2][aver]
		end

		dataset.each do |x2|
			columns_wanted.each do |y2|
				x2[y2]-=avg_max_array[y2][aver]
				x2[y2]/=avg_max_array[y2][maxi]
			end
		end
		
		row_profit = dataset.map {|x| x[@jprofit_buy_0]}
		row_profit_up = dataset.map {|x| x[@jprofit_buy_0] if x[@jprofit_buy_0]>1}.compact
		row_profit_down = dataset.map {|x| x[@jprofit_buy_0] if x[@jprofit_buy_0]<-1}.compact
	
		total_tries = [0.3,0.25,0.23, 0.22,0.2,0.18,0.15,0.13] #[0.25, 0.22] #
		up_profit, previous_up = obtain_percentage_value_up(row_profit_up, total_tries[0], "Up")
		down_profit, previous_down =obtain_percentage_value_up(row_profit_down, 0.9, "Down")
		tries=0
		up_or_down="Up"
	
		[6,5,4,3,2,1,0].each do |x|
			dataset.each do |y0|
				y0.delete_at x
			end
		end
	
		end_value = 720 #end_value is the the length of array which we'll be testing the results against
	
		total_rows = dataset.count
		end_row = (total_rows-(end_value+1))
		total_rows-=end_value
		one_third_total_rows =(total_rows*0.60).ceil  #(total_rows*0.3334).ceil
		two_third_total_rows = (total_rows*0.80).ceil#(total_rows*0.6667).ceil
		dataset_1_ori = (dataset.dup)[0..one_third_total_rows]
		dataset_2_ori = (dataset.dup)[(one_third_total_rows+1)..two_third_total_rows]
		dataset_3_ori = (dataset.dup)[(two_third_total_rows+1)..end_row]
	

	
		test_set, profit_array =dataset[0..2000], row_profit[0..2000]
		total_test = (test_set.count).to_f
		total_long,total_short = 0,0
		total_long_correct, total_short_correct = 0,0
		profit_long, profit_short, correct_long_min, correct_short_min = 0.0,0.0,0,0
		test_set.each_with_index do |v, ii|
				result = load_nbayes.classify(v)
				curr_result = result.max_class
				curr_prob = result[result.max_class]
				long, short= "Long", "Short"
				long_class_prob, short_class_prob, neutral_class_prob = result[long], result[short], result["NA"]
				if (curr_prob>0.346 && curr_result == long && short_class_prob<0.328) || (curr_prob>0.346 && curr_result == short && long_class_prob<0.328)
					total_long +=1 if curr_result==long
					total_short+=1 if curr_result==short
					#puts "#{curr_prob.round(3)}	#{curr_result}	#{test_results[ii]} #{profit_array[ii]}" #if total_long%20==0 
					if curr_result==long
						profit_long += profit_array[ii]
						correct_long_min +=1 if profit_array[ii]>0
					elsif curr_result==short
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
			
			pie = ([total_long, percentage_correct_long, percentage_correct_long_min, profit_long.round(),average_profit_long, 
			"<<Up | Down>>", total_short, percentage_correct_short,percentage_correct_short_min, profit_short.round(),average_profit_short])
			
			print pie 
			puts "	"
	end

	def current_value_fix_nbayes(current_values)
		aver,maxi = 0,1 
		@columns_wanted_dec.each do |y|
				current_values[y] -= @avg_max_array_dec[y][aver]
				current_values[y] /= @avg_max_array_dec[y][maxi]
		end
		current_values[@j_m_expected_v_18]=0
		current_values[@j_m_2_expected_v_34]=0
		current_values2 = current_values.drop(7)	
		return current_values2
	end
	
	def yule_walker_timeseries(dataset_t, points_used =50)			
		#if dataset_t.count>1102
		#	start_i = (dataset_t.count-1100)-1
		#	dataset_t=dataset_t[start_i..-1]
		#end
		
		dtf = Daru::Vector.new(
			dataset_t
		)
		number_points_used = dataset_t.count>points_used ? points_used : dataset_t.count-1
		kresult, k2 = Statsample::TimeSeries::Pacf.yule_walker(dtf,number_points_used)
		return kresult
	end #yule_walker_timeseries
	
	def linearregression(xs, ys)
  		x = GSL::Vector.alloc(xs)
  		y = GSL::Vector.alloc(ys)
  		intercept, slope, cov00, cov01, cov11, chisq, status = GSL::Fit::linear(x, y)
  		return intercept, slope, cov00, cov01, cov11, chisq
	end

end #class Backtest_Run_V_15



def sort_find_min_max_interval(all_data,position,total_intervals)

	data=all_data.sort_by {|x| x[position]}
	spread = data[-1][position]-data[0][position]
	intervals = spread/(total_intervals.to_f)
	min_value = data[0][position]

	return intervals,min_value
end

def create_new_analytics_decision_live(path, current, version)
	path_loc = "#{path}/V#{version}_backtest_analytics.csv"
	print path_loc
	#path_loc = "/home/ruby/Result_data/Parameters_11/#{current}/V11_backtest_analytics.csv"
	new_array = Array.new(50, "NEW")
	CSV.open(path_loc, 'wb' ) do |writer|  
		writer << new_array
		writer << new_array
	end	
end

def check_folder_exists(path)
	require 'fileutils'
	unless File.directory?(path)
		FileUtils.mkdir_p(path)
	end
	bayes_path = path + "/bayes"
	unless File.directory?(bayes_path)
		FileUtils.mkdir_p(bayes_path)
	end
	decision_path = path + "/decision"
	unless File.directory?(decision_path)
		FileUtils.mkdir_p(decision_path)
	end
	return 0
end

if __FILE__ == $0

	#pie = 1421916139000
	#pie2 = (Time.at(((pie/1000).to_i)).utc).strftime("%U")
	ruby_file = "/home/jwong/Documents/ruby" #"C:/Users/J Wong/Documents/ruby"
	this_version = 17
	
	all_currencies=["EURUSD"]	#"USDXVN",
	all_currencies.each do |current|
		backtest_location = ruby_file + "/backtest/V#{this_version}/#{current}"	
		p backtest_location
		check_folder_exists(backtest_location)
		create_new_analytics_decision_live(backtest_location, current, this_version)
		new_test = Backtest_Run_V_17.new(version="V#{this_version}",total_decision_needed=4, ruby_file)
		new_test.recreate_data(current, "full_2015-12-31_year",hours_held=3, lag=[3,6,12,24,48])   #lag=[12,12,12,12,12]) #
	end 


end






=begin
	
	def compile_pre_values(hour_data, minute_data, current_val)
		profit_buy,profit_24_buy, profit_48_buy, profit_72_buy=0,0,0,0
		buy_1h, buy_3h, buy_6h, buy_12h, buy_24h = minute_data[-13][@close_ask],minute_data[-37][@close_ask],minute_data[-73][@close_ask],minute_data[-145][@close_ask],minute_data[-289][@close_ask]
		##get values 3 hours, 12 hours, 24 hours, 48 hours, 72 hours ago							
		(buy_1h, buy_3h, buy_6h, buy_12h, buy_24h)=[buy_1h, buy_3h, buy_6h, buy_12h, buy_24h].map do |x|  
			x -= current_val
			x *=(-1*@@pip)
			x = x.round(1)
		end

		json = [profit_buy,profit_24_buy, profit_48_buy, profit_72_buy, 
		hour_data[@open_b],hour_data[@high_b],hour_data[@low_b],hour_data[@close_b],hour_data[@close_ask],hour_data[@candle_location],[],
		buy_1h, buy_3h, buy_6h, buy_12h, buy_24h]
		
		@j_prof_0, @j_prof_1_1, @j_prof_2_2, @j_prof_3_3, @j_open_4, @j_high_5, @j_low_6, @j_close_7, @j_cask_8, @j_loc_9, @j_dec_10 = 0,1,2,3,4,5,6,7,8,9,10
		@j_trade_11, @j_trade_12, @j_trade_13, @j_trade_14, @j_trade_15 = 11, 12, 13, 14, 15
	return json


	end  #end def periodic_movement
	

=end




