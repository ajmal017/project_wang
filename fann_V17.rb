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
	  	FastCSV.raw_parse(f) do |c|
			c0 = c[0].to_f  #profit_buy
			c1 = c[1].to_f  #profit_24_buy
			c2 = c[2].to_f  #profit_48_buy
			c3 = c[3].to_f  #profit_72_buy
			c4 = c[4].to_f  #hour_1h_n_open_b
			c5 = c[5].to_f  #hour_1h_n_high_b
			c6 = c[6].to_f  #hour_1h_n_low_b
			c7 = c[7].to_f  #hour_1h_n_close_b
			c8 = c[8].to_f  #hour_1h_nclose_ask
			c9 = c[9].to_f  #hour_1h_n_candle_location
			c10 = 0
			c11 = c[11].to_f  #buy_1h
			c12 = c[12].to_f  #buy_3h
			c13 = c[13].to_f  #buy_6h
			c14 = c[14].to_f  #buy_12h
			c15 = c[15].to_f  #buy_24h
			c16 = c[16].to_f  #regression_slope
			c17 = c[17].to_f  #errors
			c18 = c[18].to_f  #intercept_diff
			c19 = c[19].to_f  #est_diff_bid_slope
			c20 = c[20].to_f  #est_diff_ask_slope
			c21 = c[21].to_f  #regression_slope2
			c22 = c[22].to_f  #chisq_2
			c23 = c[23].to_f  #regression_slope2_cov00_2
			c24 = c[24].to_f  #regression_slope_TWO
			c25 = c[25].to_f  #errors_TWO
			c26 = c[26].to_f  #intercept_diff_TWO
			c27 = c[27].to_f  #est_diff_bid_slope_TWO
			c28 = c[28].to_f  #est_diff_ask_slope_TWO
			c29 = c[29].to_f  #regression_slope2_TWO
			c30 = c[30].to_f  #chisq_2_TWO
			c31 = c[31].to_f  #regression_slope2_cov00_2_TWO
			c32 = c[32].to_f  #regression_slope_THREE
			c33 = c[33].to_f  #errors_THREE
			c34 = c[34].to_f  #intercept_diff_THREE
			c35 = c[35].to_f  #est_diff_bid_slope_THREE
			c36 = c[36].to_f  #est_diff_ask_slope_THREE
			c37 = c[37].to_f  #regression_slope2_THREE
			c38 = c[38].to_f  #chisq_2_THREE
			c39 = c[39].to_f  #regression_slope2_cov00_2_THREE
			c40 = c[40].to_f  #regression_slope_FOUR
			c41 = c[41].to_f  #errors_FOUR
			c42 = c[42].to_f  #intercept_diff_FOUR
			c43 = c[43].to_f  #est_diff_bid_slope_FOUR
			c44 = c[44].to_f  #est_diff_ask_slope_FOUR
			c45 = c[45].to_f  #regression_slope2_FOUR
			c46 = c[46].to_f  #chisq_2_FOUR
			c47 = c[47].to_f  #regression_slope2_cov00_2_FOUR
			c48 = c[48].to_f  #regression_slope_FIVE
			c49 = c[49].to_f  #errors_FIVE
			c50 = c[50].to_f  #intercept_diff_FIVE
			c51 = c[51].to_f  #est_diff_bid_slope_FIVE
			c52 = c[52].to_f  #est_diff_ask_slope_FIVE
			c53 = c[53].to_f  #regression_slope2_FIVE
			c54 = c[54].to_f  #chisq_2_FIVE
			c55 = c[55].to_f  #regression_slope2_cov00_2_FIVE
			c56 = c[56].to_f  #pp1_1_regression_slope
			c57 = c[57].to_f  #pp1_1_errors
			c58 = c[58].to_f  #pp1_1_intercept_diff
			c59 = c[59].to_f  #pp1_1_est_diff_bid_slope
			c60 = c[60].to_f  #pp1_1_est_diff_ask_slope
			c61 = c[61].to_f  #pp1_1_regression_slope2
			c62 = c[62].to_f  #pp1_1_chisq_2
			c63 = c[63].to_f  #pp1_1_regression_slope2_cov00_2
			c64 = c[64].to_f  #pp1_1_lag_v
			c65 = c[65].to_f  #pp2_1_regression_slope
			c66 = c[66].to_f  #pp2_1_errors
			c67 = c[67].to_f  #pp2_1_intercept_diff
			c68 = c[68].to_f  #pp2_1_est_diff_bid_slope
			c69 = c[69].to_f  #pp2_1_est_diff_ask_slope
			c70 = c[70].to_f  #pp2_1_regression_slope2
			c71 = c[71].to_f  #pp2_1_chisq_2
			c72 = c[72].to_f  #pp2_1_regression_slope2_cov00_2
			c73 = c[73].to_f  #pp2_1_lag_v
			c74 = c[74].to_f  #bb1_1_regression_slope
			c75 = c[75].to_f  #bb1_1_errors
			c76 = c[76].to_f  #bb1_1_intercept_diff
			c77 = c[77].to_f  #bb1_1_est_diff_bid_slope
			c78 = c[78].to_f  #bb1_1_est_diff_ask_slope
			c79 = c[79].to_f  #bb1_1_regression_slope2
			c80 = c[80].to_f  #bb1_1_chisq_2
			c81 = c[81].to_f  #bb1_1_regression_slope2_cov00_2
			c82 = c[82].to_f  #bb1_1_lag_v
			c83 = c[83].to_f  #bb2_1_regression_slope
			c84 = c[84].to_f  #bb2_1_errors
			c85 = c[85].to_f  #bb2_1_intercept_diff
			c86 = c[86].to_f  #bb2_1_est_diff_bid_slope
			c87 = c[87].to_f  #bb2_1_est_diff_ask_slope
			c88 = c[88].to_f  #bb2_1_regression_slope2
			c89 = c[89].to_f  #bb2_1_chisq_2
			c90 = c[90].to_f  #bb2_1_regression_slope2_cov00_2
			c91 = c[91].to_f  #bb2_1_lag_v
			c92 = c[92].to_f  #pp1_2_regression_slope
			c93 = c[93].to_f  #pp1_2_errors
			c94 = c[94].to_f  #pp1_2_intercept_diff
			c95 = c[95].to_f  #pp1_2_est_diff_bid_slope
			c96 = c[96].to_f  #pp1_2_est_diff_ask_slope
			c97 = c[97].to_f  #pp1_2_regression_slope2
			c98 = c[98].to_f  #pp1_2_chisq_2
			c99 = c[99].to_f  #pp1_2_regression_slope2_cov00_2
			c100 = c[100].to_f  #pp1_2_lag_v
			c101 = c[101].to_f  #pp2_2_regression_slope
			c102 = c[102].to_f  #pp2_2_errors
			c103 = c[103].to_f  #pp2_2_intercept_diff
			c104 = c[104].to_f  #pp2_2_est_diff_bid_slope
			c105 = c[105].to_f  #pp2_2_est_diff_ask_slope
			c106 = c[106].to_f  #pp2_2_regression_slope2
			c107 = c[107].to_f  #pp2_2_chisq_2
			c108 = c[108].to_f  #pp2_2_regression_slope2_cov00_2
			c109 = c[109].to_f  #pp2_2_lag_v
			c110 = c[110].to_f  #bb1_2_regression_slope
			c111 = c[111].to_f  #bb1_2_errors
			c112 = c[112].to_f  #bb1_2_intercept_diff
			c113 = c[113].to_f  #bb1_2_est_diff_bid_slope
			c114 = c[114].to_f  #bb1_2_est_diff_ask_slope
			c115 = c[115].to_f  #bb1_2_regression_slope2
			c116 = c[116].to_f  #bb1_2_chisq_2
			c117 = c[117].to_f  #bb1_2_regression_slope2_cov00_2
			c118 = c[118].to_f  #bb1_2_lag_v
			c119 = c[119].to_f  #bb2_2_regression_slope
			c120 = c[120].to_f  #bb2_2_errors
			c121 = c[121].to_f  #bb2_2_intercept_diff
			c122 = c[122].to_f  #bb2_2_est_diff_bid_slope
			c123 = c[123].to_f  #bb2_2_est_diff_ask_slope
			c124 = c[124].to_f  #bb2_2_regression_slope2
			c125 = c[125].to_f  #bb2_2_chisq_2
			c126 = c[126].to_f  #bb2_2_regression_slope2_cov00_2
			c127 = c[127].to_f  #bb2_2_lag_v
			c128 = c[128].to_f  #m_1_ob_ex_diff
			c129 = c[129].to_f  #m_1_ob_ex_avg
			c130 = c[130].to_f  #m_1_ob_ex_max
			c131 = c[131].to_f  #m_1_sum_pos
			c132 = c[132].to_f  #m_1_sum_neg
			c133 = c[133].to_f  #m_1_std_dev
			c134 = c[134].to_f  #m_1_diff_more_stddev_two_times
			c135 = c[135].to_f  #m_1_diff_more_stddev_one_times
			c136 = c[136].to_f  #m_1_diff_more_stddev_half_times
			c137 = c[137].to_f  #m_1_diff_less_stddev_tenth
			c138 = c[138].to_f  #m_1_current_pos
			c139 = c[139].to_f  #m_1_current_neg
			c140 = c[140].to_f  #m_1_recent_24_hours_pos_neg
			c141 = c[141].to_f  #m_1_recent_12_hours_pos_neg
			c142 = c[142].to_f  #m_1_curr_less_avg
			c143 = c[143].to_f  #m_2_ob_ex_diff
			c144 = c[144].to_f  #m_2_ob_ex_avg
			c145 = c[145].to_f  #m_2_ob_ex_max
			c146 = c[146].to_f  #m_2_sum_pos
			c147 = c[147].to_f  #m_2_sum_neg
			c148 = c[148].to_f  #m_2_std_dev
			c149 = c[149].to_f  #m_2_diff_more_stddev_two_times
			c150 = c[150].to_f  #m_2_diff_more_stddev_one_times
			c151 = c[151].to_f  #m_2_diff_more_stddev_half_times
			c152 = c[152].to_f  #m_2_diff_less_stddev_tenth
			c153 = c[153].to_f  #m_2_current_pos
			c154 = c[154].to_f  #m_2_current_neg
			c155 = c[155].to_f  #m_2_recent_24_hours_pos_neg
			c156 = c[156].to_f  #m_2_recent_12_hours_pos_neg
			c157 = c[157].to_f  #m_2_curr_less_avg
			c158 = c[158].to_f  #m_3_ob_ex_diff
			c159 = c[159].to_f  #m_3_ob_ex_avg
			c160 = c[160].to_f  #m_3_ob_ex_max
			c161 = c[161].to_f  #m_3_sum_pos
			c162 = c[162].to_f  #m_3_sum_neg
			c163 = c[163].to_f  #m_3_std_dev
			c164 = c[164].to_f  #m_3_diff_more_stddev_two_times
			c165 = c[165].to_f  #m_3_diff_more_stddev_one_times
			c166 = c[166].to_f  #m_3_diff_more_stddev_half_times
			c167 = c[167].to_f  #m_3_diff_less_stddev_tenth
			c168 = c[168].to_f  #m_3_current_pos
			c169 = c[169].to_f  #m_3_current_neg
			c170 = c[170].to_f  #m_3_recent_24_hours_pos_neg
			c171 = c[171].to_f  #m_3_recent_12_hours_pos_neg
			c172 = c[172].to_f  #m_3_curr_less_avg
			c173 = c[173].to_f  #m_4_ob_ex_diff
			c174 = c[174].to_f  #m_4_ob_ex_avg
			c175 = c[175].to_f  #m_4_ob_ex_max
			c176 = c[176].to_f  #m_4_sum_pos
			c177 = c[177].to_f  #m_4_sum_neg
			c178 = c[178].to_f  #m_4_std_dev
			c179 = c[179].to_f  #m_4_diff_more_stddev_two_times
			c180 = c[180].to_f  #m_4_diff_more_stddev_one_times
			c181 = c[181].to_f  #m_4_diff_more_stddev_half_times
			c182 = c[182].to_f  #m_4_diff_less_stddev_tenth
			c183 = c[183].to_f  #m_4_current_pos
			c184 = c[184].to_f  #m_4_current_neg
			c185 = c[185].to_f  #m_4_recent_24_hours_pos_neg
			c186 = c[186].to_f  #m_4_recent_12_hours_pos_neg
			c187 = c[187].to_f  #m_4_curr_less_avg
			c188 = c[188].to_f  #predicted_1_h
			c189 = c[189].to_f  #predicted_2_h
			c190 = c[190].to_f  #predicted_1_h2
			c191 = c[191].to_f  #predicted_2_h2


			data.push([c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,
c27,c28,c29,c30,c31,c32,c33,c34,c35,c36,c37,c38,c39,c40,c41,c42,c43,c44,c45,c46,c47,c48,c49,c50,c51,c52,c53,c54,c55,c56,
c57,c58,c59,c60,c61,c62,c63,c64,c65,c66,c67,c68,c69,c70,c71,c72,c73,c74,c75,c76,c77,c78,c79,c80,c81,c82,c83,c84,c85,c86,
c87,c88,c89,c90,c91,c92,c93,c94,c95,c96,c97,c98,c99,c100,c101,c102,c103,c104,c105,c106,c107,c108,c109,c110,c111,c112,c113,c114,
c115,c116,c117,c118,c119,c120,c121,c122,c123,c124,c125,c126,c127,c128,c129,c130,c131,c132,c133,c134,c135,c136,c137,c138,c139,
c140,c141,c142,c143,c144,c145,c146,c147,c148,c149,c150,c151,c152,c153,c154,c155,c156,c157,c158,c159,c160,c161,c162,c163,c164,
c165,c166,c167,c168,c169,c170,c171,c172,c173,c174,c175,c176,c177,c178,c179,c180,c181,c182,c183,c184,c185,c186,c187,c188,c189,c190,c191])
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

def _run_fann_v17_(data_source, hours_in_trend=3)
profit_buy_0=0
profit_24_buy_1=1
profit_48_buy_2=2
profit_72_buy_3=3
hour_1h_n_open_b_4=4
hour_1h_n_high_b_5=5
hour_1h_n_low_b_6=6
hour_1h_n_close_b_7=7
hour_1h_nclose_ask_8=8
hour_1h_n_candle_location_9=9
blank_10=10
buy_1h_11=11
buy_3h_12=12
buy_6h_13=13
buy_12h_14=14
buy_24h_15=15
regression_slope_16=16
errors_17=17
intercept_diff_18=18
est_diff_bid_slope_19=19
est_diff_ask_slope_20=20
regression_slope2_21=21
chisq_2_22=22
regression_slope2_cov00_2_23=23
regression_slope_TWO_24=24
errors_TWO_25=25
intercept_diff_TWO_26=26
est_diff_bid_slope_TWO_27=27
est_diff_ask_slope_TWO_28=28
regression_slope2_TWO_29=29
chisq_2_TWO_30=30
regression_slope2_cov00_2_TWO_31=31
regression_slope_THREE_32=32
errors_THREE_33=33
intercept_diff_THREE_34=34
est_diff_bid_slope_THREE_35=35
est_diff_ask_slope_THREE_36=36
regression_slope2_THREE_37=37
chisq_2_THREE_38=38
regression_slope2_cov00_2_THREE_39=39
regression_slope_FOUR_40=40
errors_FOUR_41=41
intercept_diff_FOUR_42=42
est_diff_bid_slope_FOUR_43=43
est_diff_ask_slope_FOUR_44=44
regression_slope2_FOUR_45=45
chisq_2_FOUR_46=46
regression_slope2_cov00_2_FOUR_47=47
regression_slope_FIVE_48=48
errors_FIVE_49=49
intercept_diff_FIVE_50=50
est_diff_bid_slope_FIVE_51=51
est_diff_ask_slope_FIVE_52=52
regression_slope2_FIVE_53=53
chisq_2_FIVE_54=54
regression_slope2_cov00_2_FIVE_55=55
pp1_1_regression_slope_56=56
pp1_1_errors_57=57
pp1_1_intercept_diff_58=58
pp1_1_est_diff_bid_slope_59=59
pp1_1_est_diff_ask_slope_60=60
pp1_1_regression_slope2_61=61
pp1_1_chisq_2_62=62
pp1_1_regression_slope2_cov00_2_63=63
pp1_1_lag_v_64=64
pp2_1_regression_slope_65=65
pp2_1_errors_66=66
pp2_1_intercept_diff_67=67
pp2_1_est_diff_bid_slope_68=68
pp2_1_est_diff_ask_slope_69=69
pp2_1_regression_slope2_70=70
pp2_1_chisq_2_71=71
pp2_1_regression_slope2_cov00_2_72=72
pp2_1_lag_v_73=73
bb1_1_regression_slope_74=74
bb1_1_errors_75=75
bb1_1_intercept_diff_76=76
bb1_1_est_diff_bid_slope_77=77
bb1_1_est_diff_ask_slope_78=78
bb1_1_regression_slope2_79=79
bb1_1_chisq_2_80=80
bb1_1_regression_slope2_cov00_2_81=81
bb1_1_lag_v_82=82
bb2_1_regression_slope_83=83
bb2_1_errors_84=84
bb2_1_intercept_diff_85=85
bb2_1_est_diff_bid_slope_86=86
bb2_1_est_diff_ask_slope_87=87
bb2_1_regression_slope2_88=88
bb2_1_chisq_2_89=89
bb2_1_regression_slope2_cov00_2_90=90
bb2_1_lag_v_91=91
pp1_2_regression_slope_92=92
pp1_2_errors_93=93
pp1_2_intercept_diff_94=94
pp1_2_est_diff_bid_slope_95=95
pp1_2_est_diff_ask_slope_96=96
pp1_2_regression_slope2_97=97
pp1_2_chisq_2_98=98
pp1_2_regression_slope2_cov00_2_99=99
pp1_2_lag_v_100=100
pp2_2_regression_slope_101=101
pp2_2_errors_102=102
pp2_2_intercept_diff_103=103
pp2_2_est_diff_bid_slope_104=104
pp2_2_est_diff_ask_slope_105=105
pp2_2_regression_slope2_106=106
pp2_2_chisq_2_107=107
pp2_2_regression_slope2_cov00_2_108=108
pp2_2_lag_v_109=109
bb1_2_regression_slope_110=110
bb1_2_errors_111=111
bb1_2_intercept_diff_112=112
bb1_2_est_diff_bid_slope_113=113
bb1_2_est_diff_ask_slope_114=114
bb1_2_regression_slope2_115=115
bb1_2_chisq_2_116=116
bb1_2_regression_slope2_cov00_2_117=117
bb1_2_lag_v_118=118
bb2_2_regression_slope_119=119
bb2_2_errors_120=120
bb2_2_intercept_diff_121=121
bb2_2_est_diff_bid_slope_122=122
bb2_2_est_diff_ask_slope_123=123
bb2_2_regression_slope2_124=124
bb2_2_chisq_2_125=125
bb2_2_regression_slope2_cov00_2_126=126
bb2_2_lag_v_127=127
m_1_ob_ex_diff_128=128
m_1_ob_ex_avg_129=129
m_1_ob_ex_max_130=130
m_1_sum_pos_131=131
m_1_sum_neg_132=132
m_1_std_dev_133=133
m_1_diff_more_stddev_two_times_134=134
m_1_diff_more_stddev_one_times_135=135
m_1_diff_more_stddev_half_times_136=136
m_1_diff_less_stddev_tenth_137=137
m_1_current_pos_138=138
m_1_current_neg_139=139
m_1_recent_24_hours_pos_neg_140=140
m_1_recent_12_hours_pos_neg_141=141
m_1_curr_less_avg_142=142
m_2_ob_ex_diff_143=143
m_2_ob_ex_avg_144=144
m_2_ob_ex_max_145=145
m_2_sum_pos_146=146
m_2_sum_neg_147=147
m_2_std_dev_148=148
m_2_diff_more_stddev_two_times_149=149
m_2_diff_more_stddev_one_times_150=150
m_2_diff_more_stddev_half_times_151=151
m_2_diff_less_stddev_tenth_152=152
m_2_current_pos_153=153
m_2_current_neg_154=154
m_2_recent_24_hours_pos_neg_155=155
m_2_recent_12_hours_pos_neg_156=156
m_2_curr_less_avg_157=157
m_3_ob_ex_diff_158=158
m_3_ob_ex_avg_159=159
m_3_ob_ex_max_160=160
m_3_sum_pos_161=161
m_3_sum_neg_162=162
m_3_std_dev_163=163
m_3_diff_more_stddev_two_times_164=164
m_3_diff_more_stddev_one_times_165=165
m_3_diff_more_stddev_half_times_166=166
m_3_diff_less_stddev_tenth_167=167
m_3_current_pos_168=168
m_3_current_neg_169=169
m_3_recent_24_hours_pos_neg_170=170
m_3_recent_12_hours_pos_neg_171=171
m_3_curr_less_avg_172=172
m_4_ob_ex_diff_173=173
m_4_ob_ex_avg_174=174
m_4_ob_ex_max_175=175
m_4_sum_pos_176=176
m_4_sum_neg_177=177
m_4_std_dev_178=178
m_4_diff_more_stddev_two_times_179=179
m_4_diff_more_stddev_one_times_180=180
m_4_diff_more_stddev_half_times_181=181
m_4_diff_less_stddev_tenth_182=182
m_4_current_pos_183=183
m_4_current_neg_184=184
m_4_recent_24_hours_pos_neg_185=185
m_4_recent_12_hours_pos_neg_186=186
m_4_curr_less_avg_187=187
predicted_1_h_188=188
predicted_2_h_189=189
predicted_1_h2_190=190
predicted_2_h2_191=191
	
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
	#last_one_third_rows = ((2.0/3.0)*total_rows_0.to_f).to_i
	#total_row_2 = total_rows_0 #- last_one_third_rows
	aver,maxi = 0,1
	avg_max_array =  Array.new(total_columns) { Array.new(2,0) }  #[0,0],[0,0] ...
	columns_wanted = [
buy_1h_11,buy_3h_12,buy_6h_13,buy_12h_14,buy_24h_15,regression_slope_16,errors_17,
intercept_diff_18,est_diff_bid_slope_19,est_diff_ask_slope_20,regression_slope2_21,chisq_2_22,regression_slope2_cov00_2_23,regression_slope_TWO_24,
errors_TWO_25,intercept_diff_TWO_26,est_diff_bid_slope_TWO_27,est_diff_ask_slope_TWO_28,regression_slope2_TWO_29,chisq_2_TWO_30,regression_slope2_cov00_2_TWO_31,
regression_slope_THREE_32,errors_THREE_33,intercept_diff_THREE_34,est_diff_bid_slope_THREE_35,est_diff_ask_slope_THREE_36,regression_slope2_THREE_37,
chisq_2_THREE_38,regression_slope2_cov00_2_THREE_39,regression_slope_FOUR_40,errors_FOUR_41,intercept_diff_FOUR_42,
est_diff_bid_slope_FOUR_43,est_diff_ask_slope_FOUR_44,regression_slope2_FOUR_45,chisq_2_FOUR_46,regression_slope2_cov00_2_FOUR_47,
regression_slope_FIVE_48,errors_FIVE_49,intercept_diff_FIVE_50,est_diff_bid_slope_FIVE_51,est_diff_ask_slope_FIVE_52,
regression_slope2_FIVE_53,chisq_2_FIVE_54,regression_slope2_cov00_2_FIVE_55,pp1_1_regression_slope_56,pp1_1_errors_57,pp1_1_intercept_diff_58,
pp1_1_est_diff_bid_slope_59,pp1_1_est_diff_ask_slope_60,pp1_1_regression_slope2_61,pp1_1_chisq_2_62,pp1_1_regression_slope2_cov00_2_63,pp1_1_lag_v_64,
pp2_1_regression_slope_65,pp2_1_errors_66,pp2_1_intercept_diff_67,pp2_1_est_diff_bid_slope_68,pp2_1_est_diff_ask_slope_69,pp2_1_regression_slope2_70,
pp2_1_chisq_2_71,pp2_1_regression_slope2_cov00_2_72,pp2_1_lag_v_73,bb1_1_regression_slope_74,bb1_1_errors_75,bb1_1_intercept_diff_76,
bb1_1_est_diff_bid_slope_77,bb1_1_est_diff_ask_slope_78,bb1_1_regression_slope2_79,bb1_1_chisq_2_80,bb1_1_regression_slope2_cov00_2_81,bb1_1_lag_v_82,
bb2_1_regression_slope_83,bb2_1_errors_84,bb2_1_intercept_diff_85,bb2_1_est_diff_bid_slope_86,bb2_1_est_diff_ask_slope_87,bb2_1_regression_slope2_88,
bb2_1_chisq_2_89,bb2_1_regression_slope2_cov00_2_90,bb2_1_lag_v_91,pp1_2_regression_slope_92,pp1_2_errors_93,pp1_2_intercept_diff_94,
pp1_2_est_diff_bid_slope_95,pp1_2_est_diff_ask_slope_96,pp1_2_regression_slope2_97,pp1_2_chisq_2_98,pp1_2_regression_slope2_cov00_2_99,pp1_2_lag_v_100,
pp2_2_regression_slope_101,pp2_2_errors_102,pp2_2_intercept_diff_103,pp2_2_est_diff_bid_slope_104,pp2_2_est_diff_ask_slope_105,pp2_2_regression_slope2_106,
pp2_2_chisq_2_107,pp2_2_regression_slope2_cov00_2_108,pp2_2_lag_v_109,bb1_2_regression_slope_110,bb1_2_errors_111,bb1_2_intercept_diff_112,
bb1_2_est_diff_bid_slope_113,bb1_2_est_diff_ask_slope_114,bb1_2_regression_slope2_115,bb1_2_chisq_2_116,bb1_2_regression_slope2_cov00_2_117,bb1_2_lag_v_118,
bb2_2_regression_slope_119,bb2_2_errors_120,bb2_2_intercept_diff_121,bb2_2_est_diff_bid_slope_122,bb2_2_est_diff_ask_slope_123,bb2_2_regression_slope2_124,
bb2_2_chisq_2_125,bb2_2_regression_slope2_cov00_2_126,bb2_2_lag_v_127,m_1_ob_ex_diff_128,m_1_ob_ex_avg_129,m_1_ob_ex_max_130,
m_1_sum_pos_131,m_1_sum_neg_132,m_1_std_dev_133,m_1_diff_more_stddev_two_times_134,m_1_diff_more_stddev_one_times_135,m_1_diff_more_stddev_half_times_136,
m_1_diff_less_stddev_tenth_137,m_1_current_pos_138,m_1_current_neg_139,m_1_recent_24_hours_pos_neg_140,m_1_recent_12_hours_pos_neg_141,m_1_curr_less_avg_142,
m_2_ob_ex_diff_143,m_2_ob_ex_avg_144,m_2_ob_ex_max_145,m_2_sum_pos_146,m_2_sum_neg_147,m_2_std_dev_148,m_2_diff_more_stddev_two_times_149,
m_2_diff_more_stddev_one_times_150,m_2_diff_more_stddev_half_times_151,m_2_diff_less_stddev_tenth_152,m_2_current_pos_153,m_2_current_neg_154,m_2_recent_24_hours_pos_neg_155,
m_2_recent_12_hours_pos_neg_156,m_2_curr_less_avg_157,m_3_ob_ex_diff_158,m_3_ob_ex_avg_159,m_3_ob_ex_max_160,m_3_sum_pos_161,
m_3_sum_neg_162,m_3_std_dev_163,m_3_diff_more_stddev_two_times_164,m_3_diff_more_stddev_one_times_165,m_3_diff_more_stddev_half_times_166,m_3_diff_less_stddev_tenth_167,
m_3_current_pos_168,m_3_current_neg_169,m_3_recent_24_hours_pos_neg_170,m_3_recent_12_hours_pos_neg_171,m_3_curr_less_avg_172,m_4_ob_ex_diff_173,
m_4_ob_ex_avg_174,m_4_ob_ex_max_175,m_4_sum_pos_176,m_4_sum_neg_177,m_4_std_dev_178,m_4_diff_more_stddev_two_times_179,
m_4_diff_more_stddev_one_times_180,m_4_diff_more_stddev_half_times_181,m_4_diff_less_stddev_tenth_182,m_4_current_pos_183,m_4_current_neg_184,m_4_recent_24_hours_pos_neg_185,
m_4_recent_12_hours_pos_neg_186,m_4_curr_less_avg_187,predicted_1_h_188,predicted_2_h_189,predicted_1_h2_190,predicted_2_h2_191]  

	long, short= "Long", "Short"
	default_opposing_percentage = 0.90

	dataset_t = dataset.deep_dup.transpose
	dataset.clear
#	dataset_t.slice!(0)
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
			x2 =1 if x2>1  #this is to give a max value of 1 instead of allowing the big values to skew the data
			x2 =-1 if x2<-1 
			x2
		end
	end

	
	row_profit_ori = dataset_t[profit_buy_0].map {|x| x}
	row_profit = normalize_std_profit(row_profit_ori.deep_dup)
	row_profit_up = row_profit.map {|x| x if x>0.05}.compact
	row_profit_down = row_profit.map {|x| x if x<-0.05}.compact

	#up_profit, previous_up = obtain_percentage_value_up(row_profit_up, total_tries[0], "Up")
	#down_profit, previous_down =obtain_percentage_value_up(row_profit_down, default_opposing_percentage, "Down")
	
	up_or_down="Up"
	
	[blank_10,hour_1h_n_candle_location_9,hour_1h_nclose_ask_8,hour_1h_n_close_b_7,hour_1h_n_low_b_6,hour_1h_n_high_b_5,hour_1h_n_open_b_4,
	profit_72_buy_3,profit_48_buy_2,profit_24_buy_1,profit_buy_0].each do |x| #removes profit_buy_0,jprofit_24_buy_1,jprofit_48_buy_2,jprofit_72_buy_3, jcandleloc_4,jclosebid_5,jcloseask_6
		dataset_t.delete_at x
	end
	dataset = dataset_t.deep_dup.transpose
	dataset_t.clear
	total_rows = dataset.count #have to calculate again after removing validation_set


	total_test_val = 3000#(total_rows_0*0.2).to_i #total_test_val is the the length of array which we'll be testing the results against # count_removal_last_hours is due to the time gap between last prediction and first possible prediction
	end_of_40_percent_row = (total_rows*0.40).ceil
	validation_set, validation_results, profit_rand_set =[],[],[]

	#want to test k-validation, hence testing the data 3 times (basically if it approves of trade twice or more, then it's a go)


	#extract profit array first
	
	profit_array_1 = (row_profit_ori[0..total_test_val-1] ).deep_dup
	profit_array_2 = (row_profit_ori[end_of_40_percent_row+1..(end_of_40_percent_row+total_test_val)]).deep_dup
	profit_array_3 = (row_profit_ori[total_rows-total_test_val..-1]).deep_dup
	test_array_1 = (dataset[0..total_test_val-1]).dup 
	test_array_2 = (dataset[end_of_40_percent_row+1..(end_of_40_percent_row+total_test_val)]).deep_dup
	test_array_3 = (dataset[total_rows-total_test_val..-1]).deep_dup

	p profit_array_1.count == test_array_1.count && profit_array_2.count == test_array_2.count && profit_array_3.count == test_array_3.count
	
	
	end_row = (total_rows-total_test_val)
	one_third_total_rows =(total_rows*0.60).ceil  #(total_rows*0.3334).ceil
	two_third_total_rows = (total_rows*0.80).ceil#(total_rows*0.6667).ceil
	dataset_1_ori = (dataset.dup)[0..one_third_total_rows]
	dataset_2_ori = (dataset.dup)[(one_third_total_rows+1)..two_third_total_rows]
	dataset_3_ori = (dataset.dup)[(two_third_total_rows+1)..end_row]
	test_set = (dataset.dup)[end_row+1..-1]
	profit_array = (row_profit_ori.dup)[total_rows_0-total_test_val+1..-1] # use total_rows_0 here because no slicing of row_profit, and since random_gen doesnt include end_values
	


	#test_set.concat(validation_set)
	#profit_array.concat(profit_rand_set)
		###
		#profit_array=(row_profit.dup)[(two_third_total_rows+1)..end_row]
		###
	validation_set.clear
	profit_rand_set.clear
	tot_data_col = dataset[0].count
	all_results, wanted_up_results, wanted_down_results=[], [], []
										############ start total_tries!! ############
	#while tries < total_tries.count		
		#if up_or_down=="Up" && tries!=0
		#	up_profit, previous_up = obtain_percentage_value_up(row_profit_up, total_tries[tries], up_or_down, previous_up)
		#elsif up_or_down=="Down" && tries!=0
		#	down_profit, previous_down =obtain_percentage_value_up(row_profit_down, total_tries[tries], up_or_down, previous_down)
		#end
		total_up, total_down = 0, 0
		result_array = nil
		result_array =[]

		row_profit.each do |x|
			if x>=0
				result_array << [x,0] 
				total_up +=1
			elsif x<0
				result_array << [0,-x]
				total_down+=1
			end
		end
		
		#validation_results.clear
		#random_gen.each do |gg|
		#	validation_results << result_array[gg]
		#	result_array.slice!(gg)
		#end

		test_results = (result_array.dup)[end_row+1..-1]
		#test_results.concat(validation_results)
		#validation_results.clear
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

		result_array.clear

													####FANN TRAINING###
		hid_lay_1 = (tot_data_col*2).to_i
		hid_lay_2 = (tot_data_col*1).to_i
		hid_lay_3 = (hid_lay_2*0.5).to_i
		hid_lay_4 = (hid_lay_3*0.5).to_i
		p hid_lay_4
		puts 'initializing'
		train1 = RubyFann::TrainData.new(:inputs=>dataset_1, :desired_outputs=>result_array_1)
		train2 = RubyFann::TrainData.new(:inputs=>dataset_2, :desired_outputs=>result_array_2)
		train3 = RubyFann::TrainData.new(:inputs=>dataset_3, :desired_outputs=>result_array_3)
		#unless defined? fann
		fann = RubyFann::Standard.new(:num_inputs=>tot_data_col, :hidden_neurons=>[hid_lay_1, hid_lay_2, hid_lay_3], :num_outputs=>2) #, hid_lay_3, hid_lay_4], :num_outputs=>2)
		#end
		  	fann.randomize_weights(-0.1, 0.1)
		  	#fann.set_learning_rate(0.2)
		  	fann.set_training_algorithm(:rprop) 
		  	fann.set_activation_function_hidden(:sigmoid_symmetric)
  			fann.set_activation_function_output(:sigmoid_symmetric)
  		p 'training'
  		start_t = Time.now
		fann.train_on_data(train1, 20, 200, 0.001) 
		dataset_1.clear	
		result_array_1.clear
		p 'first training done'
		p_end_diff_time(start_t)
		
		start_t = Time.now
		fann.train_on_data(train3, 20, 100, 0.001) # 4 max_epochs, 10 errors between reports and 0.1 desired MSE (mean-squared-error)   
		dataset_3.clear
		result_array_3.clear
		p 'second training'
		p_end_diff_time(start_t)
		
		start_t = Time.now
		fann.train_on_data(train2, 20, 100, 0.001)
		dataset_2.clear
		result_array_2.clear
		p 'all training done'
		p_end_diff_time(start_t)
		start_t = Time.now


		##
		total_test = (test_set.count).to_f
		total_long,total_short = 0,0
		total_long_correct, total_short_correct = 0,0
		profit_long, profit_short, correct_long_min, correct_short_min = 0.0,0.0,0,0
		long_i, short_i, na_i =0,1,2

		max_tries = 5
		tries = 0

		while tries <max_tries
		total_long,total_short = 0,0
		total_long_correct, total_short_correct = 0,0
		profit_long, profit_short, correct_long_min, correct_short_min = 0.0,0.0,0,0
		test_set.each_index do |ii|
			result = fann.run(test_set[ii])
			curr_prob = result.max
			alt_prob = result.min
			curr_result = result.rindex(curr_prob)
			alt_result = curr_result==1 ? 0 : 1
			p "#{result}	: #{curr_result}" if ii%100==0
			long_class_prob, short_class_prob, neutral_class_prob = result[long_i], result[short_i]#, result[na_i]
			#min_prob, max_alt_prob =0.40, 0.04
			max_alt_prob = (result.min+0.00001)
			min_prob = max_alt_prob*20   #this means we only accept if it is 20 times more likely than the opposing result.
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
		if percentage_correct_long_min>=minimum_percentage_min && percentage_correct_long>=minimum_percentage #up_or_down=="Up" && 
#			if ((total_long>=min_0 && total_long<min_1 && average_profit_long>=20.0 && percentage_correct_long_min>=0.80) || (total_long>=min_1 && total_long<min_2 && average_profit_long>=10.0 && percentage_correct_long_min>=0.70) || (total_long>=min_2 && average_profit_long>=8.0))
#				wanted_up_results.push([tries,total_long, percentage_correct_long, percentage_correct_long_min, profit_long.round(),average_profit_long, up_profit, down_profit])
#			end
		elsif percentage_correct_short_min>=minimum_percentage_min && percentage_correct_short>=minimum_percentage #up_or_down=="Down" && 
#			if ((total_short>=min_0 && total_short<min_1 && average_profit_short>=20.0 && percentage_correct_short_min>=0.80) || (total_short>=min_1 && total_short<min_2 && average_profit_short>=10.0 && percentage_correct_long_min>=0.70) || (total_short>=min_2 && average_profit_short>=8.0))
#				wanted_down_results.push([tries,total_short, percentage_correct_short,percentage_correct_short_min, profit_short.round(),average_profit_short, up_profit, down_profit])
#			end
		end
		
		all_results.push([up_or_down, tries,total_long, percentage_correct_long, percentage_correct_long_min, profit_long.round(),average_profit_long, 
		"<<Up | Down>>", total_short, percentage_correct_short,percentage_correct_short_min, profit_short.round(),average_profit_short])

		p all_results
		#test_results.clear
		#sfann=nil

		long_condition = (total_long>50 && percentage_correct_long_min>minimum_percentage_min && average_profit_long>5)
		short_condition = (total_short>50 && percentage_correct_short_min>minimum_percentage_min && average_profit_short>5)
		redo_condition = ((total_long<10 && (percentage_correct_long_min<0.40 || percentage_correct_long_min.nan?) && average_profit_long<1.0) || (total_short<10 && (percentage_correct_short_min<0.10 || percentage_correct_short_min.nan?) && average_profit_short<1.0))
		if (long_condition && short_condition)
			tries += max_tries
		else
			tries+=1
			if tries%2==0
					if redo_condition
						fann.randomize_weights(-0.2, 0.2)
						tries-=1
					end
				
				fann.set_training_algorithm(:quickprop) 
			else
				fann.set_training_algorithm(:rprop) 
			end
			

			p 'training'
	  		start_t = Time.now
			fann.train_on_data(train1, 30, 200, 0.001) 
			dataset_1.clear	
			result_array_1.clear
			p "#{tries} first training done"
			p_end_diff_time(start_t)
			
			start_t = Time.now
			fann.train_on_data(train3, 30, 100, 0.001) # 4 max_epochs, 10 errors between reports and 0.1 desired MSE (mean-squared-error)   
			dataset_3.clear
			result_array_3.clear
			p "#{tries} second training"
			p_end_diff_time(start_t)
			
			start_t = Time.now
			fann.train_on_data(train2, 30, 100, 0.001)
			dataset_2.clear
			result_array_2.clear
			p "#{tries} all training done"
			p_end_diff_time(start_t)
			start_t = Time.now
			
		end
	#	if tries == total_tries.count && up_or_down=="Up"
	#		tries=0
	#		up_or_down="Down"
	#		up_profit, previous_up = obtain_percentage_value_up(row_profit_up, default_opposing_percentage, "Up", previous_up)
	#		down_profit, previous_down =obtain_percentage_value_up(row_profit_down, total_tries[0], "Down", previous_down)	
	#	end	

	end #run tries < max_tries twice up_or_down
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

def p_end_diff_time(start_time)
	finish_t = Time.now
	p "#{((finish_t-start_time))} seconds"
end

if __FILE__ == $0
 
	Benchmark.bm do |bm|

		bm.report do
			ruby_file = "/home/jwong/Documents/ruby" #"C:/Users/J Wong/Documents/ruby"
			data_file = ruby_file + "/test/fann_test"#{}"/backtest/V16/EURUSD"
			fann_folder = data_file + "/fann"
			data_source	= data_file + "/EURUSD_V17_training_set.csv"
			dataset, row_profit, up_results, down_results, final_results, avg_max_array, columns_wanted = _run_fann_v17_(data_source)
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



