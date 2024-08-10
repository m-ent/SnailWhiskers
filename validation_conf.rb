# hp_id の validationを行う場合、@@state = true に設定する

class Id_validation
  @@state = false
  def self.state; @@state; end
  def self.enable; @@state = true; end
  def self.disable; @@state = false; end
end
