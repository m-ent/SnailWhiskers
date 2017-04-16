module Helpers
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['audioadmin', 'audioadmin']
  end

  def pluralize(amount, noun)
    irregular = {'datum' => 'data',
                 'person' => 'people'}
    if amount > 1
      "#{amount} #{irregular.has_key?(noun) ? irregular[noun] : noun + 's'}"
    else
      "#{amount == 1 ? 1 : "no"} #{noun}"
    end
  end

  def cycle  # returns true, false, true, false, ...
    @state ||= false
    @state = not(@state)
    @state
  end

  def image_tag(img_file)
    "<img alt=\"#{img_file}\" src=\"#{img_file}\" />"
  end

  def h(text)
    # Ref: How do I escape HTML? http://www.sinatrarb.com/faq.html#escape_html
    Rack::Utils.escape_html(text)
  end

  def time_element(time)
    t = time.getlocal
    return {year: t.strftime("%Y"), month: t.strftime("%m"), day: t.strftime("%d"), 
            hour: t.strftime("%H"), min: t.strftime("%M"), sec: t.strftime("%S")}
  end

  def reg_id(id)
    id = id[0..9] if id.length > 10
    r_id = "0" * (10-id.length) + id
    return "#{r_id[0..4]}-#{r_id[5..9]}" # xxxxx-xxxxx の形式
  end

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
    result_R = (result_R).round(1) if result_R.class == Float
    result_L = (result_L).round(1) if result_L.class == Float
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
end
