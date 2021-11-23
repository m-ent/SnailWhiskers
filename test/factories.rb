FactoryBot.define do
  factory :patient do
    hp_id { "19" } # valid hp_id
  end

  factory :audiogram do
    examdate { Time.now }
    comment { nil }
    audiometer { "AA-79S" }
    hospital { "Hospital_A" }
    image_location { nil }
    manual_input { nil }
#    ac_rt_125 
#    ac_rt_250 
    ac_rt_500 { 10 }
    ac_rt_1k  { 20 }
    ac_rt_2k  { 30 }
    ac_rt_4k  { 40 }
#    ac_rt_8k 
#    ac_lt_125 
#    ac_lt_250 
    ac_lt_500 { 15 }
    ac_lt_1k  { 25 }
    ac_lt_2k  { 30 }
    ac_lt_4k  { 45 }
#    ac_lt_8k 
=begin
    ac_rt_125_scaleout 
    ac_rt_250_scaleout 
    ac_rt_500_scaleout 
    ac_rt_1k_scaleout 
    ac_rt_2k_scaleout 
    ac_rt_4k_scaleout 
    ac_rt_8k_scaleout 
    ac_lt_125_scaleout 
    ac_lt_250_scaleout 
    ac_lt_500_scaleout 
    ac_lt_1k_scaleout 
    ac_lt_2k_scaleout 
    ac_lt_4k_scaleout 
    ac_lt_8k_scaleout 
    bc_rt_250 
    bc_rt_500 
    bc_rt_1k 
    bc_rt_2k 
    bc_rt_4k 
    bc_rt_8k 
    bc_lt_250 
    bc_lt_500 
    bc_lt_1k 
    bc_lt_2k 
    bc_lt_4k 
    bc_lt_8k 
    bc_rt_250_scaleout 
    bc_rt_500_scaleout 
    bc_rt_1k_scaleout 
    bc_rt_2k_scaleout 
    bc_rt_4k_scaleout 
    bc_rt_8k_scaleout 
    bc_lt_250_scaleout 
    bc_lt_500_scaleout 
    bc_lt_1k_scaleout 
    bc_lt_2k_scaleout 
    bc_lt_4k_scaleout 
    bc_lt_8k_scaleout 
    mask_ac_rt_125 
    mask_ac_rt_250 
    mask_ac_rt_500 
    mask_ac_rt_1k 
    mask_ac_rt_2k 
    mask_ac_rt_4k 
    mask_ac_rt_8k 
    mask_ac_lt_125 
    mask_ac_lt_250 
    mask_ac_lt_500 
    mask_ac_lt_1k 
    mask_ac_lt_2k 
    mask_ac_lt_4k 
    mask_ac_lt_8k 
    mask_ac_rt_125_type 
    mask_ac_rt_250_type 
    mask_ac_rt_500_type 
    mask_ac_rt_1k_type 
    mask_ac_rt_2k_type 
    mask_ac_rt_4k_type 
    mask_ac_rt_8k_type 
    mask_ac_lt_125_type 
    mask_ac_lt_250_type 
    mask_ac_lt_500_type 
    mask_ac_lt_1k_type 
    mask_ac_lt_2k_type 
    mask_ac_lt_4k_type 
    mask_ac_lt_8k_type 
    mask_bc_rt_250 
    mask_bc_rt_500 
    mask_bc_rt_1k 
    mask_bc_rt_2k 
    mask_bc_rt_4k 
    mask_bc_rt_8k 
    mask_bc_lt_250 
    mask_bc_lt_500 
    mask_bc_lt_1k 
    mask_bc_lt_2k 
    mask_bc_lt_4k 
    mask_bc_lt_8k 
    mask_bc_rt_250_type 
    mask_bc_rt_500_type 
    mask_bc_rt_1k_type 
    mask_bc_rt_2k_type 
    mask_bc_rt_4k_type 
    mask_bc_rt_8k_type
    mask_bc_lt_250_type 
    mask_bc_lt_500_type 
    mask_bc_lt_1k_type 
    mask_bc_lt_2k_type 
    mask_bc_lt_4k_type 
    mask_bc_lt_8k_type 
=end
  end

=begin
  factory :tympanogram do
    examdate Time.now
    comment nil
    impedancemeter "RS-22"
    hospital "NEMC"
    image_location nil

    rt_pvt 0.0
    rt_sc 0.1
    rt_peak 1
    rt_interval 0.2
    rt_data ""
    rt_data_length 10
    lt_pvt 0.3
    lt_sc 0.4
    lt_peak 2
    lt_interval 0.5
    lt_data " "
    lt_data_length 11
  end
=end
end
