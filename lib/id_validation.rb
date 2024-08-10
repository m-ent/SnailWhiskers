# ID validation for Nagoya Municipal East Medical Center, Higashi Municipal Hosptial

require_relative '../validation_conf'

def valid_id?(id_str)
  if Id_validation::state # hp_id の validation をする場合: validation_conf.rb で設定
    return false if !id_str
    id  = id_str.delete("^0-9") # remove non-number
    if id == ""
      return false
    end
    if id.length > 10
      return false
    end
    if valid_checksum?(id)
      return  "0" * (10-id.length) + id  # return id as a 10-digit number
    else
      return false
    end
  else
    id  = id_str.delete("^0-9") # remove non-number
    return  "0" * (10-id.length) + id  # return id as a 10-digit number
  end
end

def valid_checksum?(id)
  # hp_id の validation をする場合のみ呼ばれる
  # Rule for Nagoya East Medical Center
  id1 = id.to_i / 10
  id2 = id.to_i % 10
  check_sum =  (id1 / 100000) % 10 * 7
  check_sum += (id1 / 10000) % 10 * 6
  check_sum += (id1 / 1000) % 10 * 5
  check_sum += (id1 / 100) % 10 * 4
  check_sum += (id1 / 10) % 10 * 3
  check_sum += (id1 % 10) * 2
  rem = check_sum % 11
  check_sum = 11 - rem
  if check_sum > 9
    check_sum = 0
  end
  if check_sum == id2
    true
  else
    false
  end
end
