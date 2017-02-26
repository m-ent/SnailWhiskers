module Helpers
  def reg_id(id)
    id = id[0..9] if id.length > 10
    r_id = "0" * (10-id.length) + id
    return "#{r_id[0..4]}-#{r_id[5..9]}" # xxxxx-xxxxx の形式
  end

=begin
  def mean(mode, audiogram)
    a = {:r5 => audiogram.ac_rt_500, :r1 => audiogram.ac_rt_1k,\
         :r2 => audiogram.ac_rt_2k,  :r4 => audiogram.ac_rt_4k,\
         :l5 => audiogram.ac_lt_500, :l1 => audiogram.ac_lt_1k,\
	 :l2 => audiogram.ac_lt_2k,  :l4 => audiogram.ac_lt_4k}
    case mode
    when "3"
      result_R = (a[:r5] + a[:r1] + a[:r2])/3.0 rescue "--"
      result_L = (a[:l5] + a[:l1] + a[:l2])/3.0 rescue "--"
    when "4"
      result_R = (a[:r5] + 2 * a[:r1] + a[:r2])/4.0 rescue "--"
      result_L = (a[:l5] + 2 * a[:l1] + a[:l2])/4.0 rescue "--"
    when "4R"
      result_R, result_L = reg4R(audiogram)
    when "6"
      result_R = (a[:r5] + 2 * a[:r1] + 2 * a[:r2] + a[:r4])/6.0 rescue "--"
      result_L = (a[:l5] + 2 * a[:l1] + 2 * a[:l2] + a[:l4])/6.0 rescue "--"
    end
    result_R = round1(result_R) if result_R.class == Float
    result_L = round1(result_L) if result_L.class == Float
    return {:R => result_R, :L => result_L}
  end

  private
  def reg4R(audiogram)
    result = Array.new
    if audiogram.ac_rt_500 && audiogram.ac_rt_1k && audiogram.ac_rt_2k 
      r =  (audiogram.ac_rt_500 > 100.0 or audiogram.ac_rt_500_scaleout) ?\
            105.0 : audiogram.ac_rt_500
      r += (audiogram.ac_rt_1k > 100.0 or audiogram.ac_rt_1k_scaleout) ?\
            105.0 * 2 : audiogram.ac_rt_1k * 2
      r += (audiogram.ac_rt_2k > 100.0 or audiogram.ac_rt_2k_scaleout) ?\
            105.0 : audiogram.ac_rt_2k
      result << r/4.0
    else
      result << "--"
    end
    if audiogram.ac_lt_500 && audiogram.ac_lt_1k && audiogram.ac_lt_2k 
      l =  (audiogram.ac_lt_500 > 100.0 or audiogram.ac_lt_500_scaleout) ?\
            105.0 : audiogram.ac_lt_500
      l += (audiogram.ac_lt_1k > 100.0 or audiogram.ac_lt_1k_scaleout) ?\
            105.0 * 2 : audiogram.ac_lt_1k * 2
      l += (audiogram.ac_lt_2k > 100.0 or audiogram.ac_lt_2k_scaleout) ?\
            105.0 : audiogram.ac_lt_2k
      result << l/4.0
    else
      result << "--"
    end
    return result
  end

  def round1(r)  # 小数点1位で四捨五入
    return (r * 10.0).round / 10.0
  end
=end

end
