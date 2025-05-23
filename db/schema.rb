# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2017_02_19_133546) do
  create_table "audiograms", force: :cascade do |t|
    t.integer "patient_id"
    t.datetime "examdate", precision: nil
    t.string "comment"
    t.string "image_location"
    t.float "ac_rt_125"
    t.float "ac_rt_250"
    t.float "ac_rt_500"
    t.float "ac_rt_1k"
    t.float "ac_rt_2k"
    t.float "ac_rt_4k"
    t.float "ac_rt_8k"
    t.float "ac_lt_125"
    t.float "ac_lt_250"
    t.float "ac_lt_500"
    t.float "ac_lt_1k"
    t.float "ac_lt_2k"
    t.float "ac_lt_4k"
    t.float "ac_lt_8k"
    t.float "bc_rt_250"
    t.float "bc_rt_500"
    t.float "bc_rt_1k"
    t.float "bc_rt_2k"
    t.float "bc_rt_4k"
    t.float "bc_rt_8k"
    t.float "bc_lt_250"
    t.float "bc_lt_500"
    t.float "bc_lt_1k"
    t.float "bc_lt_2k"
    t.float "bc_lt_4k"
    t.float "bc_lt_8k"
    t.boolean "ac_rt_125_scaleout"
    t.boolean "ac_rt_250_scaleout"
    t.boolean "ac_rt_500_scaleout"
    t.boolean "ac_rt_1k_scaleout"
    t.boolean "ac_rt_2k_scaleout"
    t.boolean "ac_rt_4k_scaleout"
    t.boolean "ac_rt_8k_scaleout"
    t.boolean "ac_lt_125_scaleout"
    t.boolean "ac_lt_250_scaleout"
    t.boolean "ac_lt_500_scaleout"
    t.boolean "ac_lt_1k_scaleout"
    t.boolean "ac_lt_2k_scaleout"
    t.boolean "ac_lt_4k_scaleout"
    t.boolean "ac_lt_8k_scaleout"
    t.boolean "bc_rt_250_scaleout"
    t.boolean "bc_rt_500_scaleout"
    t.boolean "bc_rt_1k_scaleout"
    t.boolean "bc_rt_2k_scaleout"
    t.boolean "bc_rt_4k_scaleout"
    t.boolean "bc_rt_8k_scaleout"
    t.boolean "bc_lt_250_scaleout"
    t.boolean "bc_lt_500_scaleout"
    t.boolean "bc_lt_1k_scaleout"
    t.boolean "bc_lt_2k_scaleout"
    t.boolean "bc_lt_4k_scaleout"
    t.boolean "bc_lt_8k_scaleout"
    t.float "mask_ac_rt_125"
    t.float "mask_ac_rt_250"
    t.float "mask_ac_rt_500"
    t.float "mask_ac_rt_1k"
    t.float "mask_ac_rt_2k"
    t.float "mask_ac_rt_4k"
    t.float "mask_ac_rt_8k"
    t.float "mask_ac_lt_125"
    t.float "mask_ac_lt_250"
    t.float "mask_ac_lt_500"
    t.float "mask_ac_lt_1k"
    t.float "mask_ac_lt_2k"
    t.float "mask_ac_lt_4k"
    t.float "mask_ac_lt_8k"
    t.float "mask_bc_rt_250"
    t.float "mask_bc_rt_500"
    t.float "mask_bc_rt_1k"
    t.float "mask_bc_rt_2k"
    t.float "mask_bc_rt_4k"
    t.float "mask_bc_rt_8k"
    t.float "mask_bc_lt_250"
    t.float "mask_bc_lt_500"
    t.float "mask_bc_lt_1k"
    t.float "mask_bc_lt_2k"
    t.float "mask_bc_lt_4k"
    t.float "mask_bc_lt_8k"
    t.string "mask_ac_rt_125_type"
    t.string "mask_ac_rt_250_type"
    t.string "mask_ac_rt_500_type"
    t.string "mask_ac_rt_1k_type"
    t.string "mask_ac_rt_2k_type"
    t.string "mask_ac_rt_4k_type"
    t.string "mask_ac_rt_8k_type"
    t.string "mask_ac_lt_125_type"
    t.string "mask_ac_lt_250_type"
    t.string "mask_ac_lt_500_type"
    t.string "mask_ac_lt_1k_type"
    t.string "mask_ac_lt_2k_type"
    t.string "mask_ac_lt_4k_type"
    t.string "mask_ac_lt_8k_type"
    t.string "mask_bc_rt_250_type"
    t.string "mask_bc_rt_500_type"
    t.string "mask_bc_rt_1k_type"
    t.string "mask_bc_rt_2k_type"
    t.string "mask_bc_rt_4k_type"
    t.string "mask_bc_rt_8k_type"
    t.string "mask_bc_lt_250_type"
    t.string "mask_bc_lt_500_type"
    t.string "mask_bc_lt_1k_type"
    t.string "mask_bc_lt_2k_type"
    t.string "mask_bc_lt_4k_type"
    t.string "mask_bc_lt_8k_type"
    t.boolean "manual_input"
    t.string "audiometer"
    t.string "hospital"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["patient_id"], name: "index_audiograms_on_patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.string "hp_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

end
