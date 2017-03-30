# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170330163412) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "students", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "students", ["user_id"], name: "index_students_on_user_id", using: :btree

  create_table "teacher_friday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_friday_time_frames", ["teacher_id"], name: "index_teacher_friday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_holidays", force: :cascade do |t|
    t.integer  "teacher_id"
    t.date     "holiday_date"
    t.string   "description"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "teacher_holidays", ["teacher_id"], name: "index_teacher_holidays_on_teacher_id", using: :btree

  create_table "teacher_images", force: :cascade do |t|
    t.integer  "teacher_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "teacher_images", ["teacher_id"], name: "index_teacher_images_on_teacher_id", using: :btree

  create_table "teacher_monday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_monday_time_frames", ["teacher_id"], name: "index_teacher_monday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_price_ranges", force: :cascade do |t|
    t.float    "thirty_minute_session"
    t.float    "sixty_minute_session"
    t.float    "ninety_minute_session"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "teacher_ratings", force: :cascade do |t|
    t.integer  "teacher_id"
    t.integer  "student_id"
    t.integer  "score"
    t.string   "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "teacher_ratings", ["student_id"], name: "index_teacher_ratings_on_student_id", using: :btree
  add_index "teacher_ratings", ["teacher_id"], name: "index_teacher_ratings_on_teacher_id", using: :btree

  create_table "teacher_saturday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_saturday_time_frames", ["teacher_id"], name: "index_teacher_saturday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_sunday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_sunday_time_frames", ["teacher_id"], name: "index_teacher_sunday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_thursday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_thursday_time_frames", ["teacher_id"], name: "index_teacher_thursday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_time_frame_blacklists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teacher_tuesday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_tuesday_time_frames", ["teacher_id"], name: "index_teacher_tuesday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_wednesday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_wednesday_time_frames", ["teacher_id"], name: "index_teacher_wednesday_time_frames_on_teacher_id", using: :btree

  create_table "teachers", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "teachers", ["user_id"], name: "index_teachers_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "teacher_or_student"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "yoga_types", force: :cascade do |t|
    t.integer  "teacher_id"
    t.integer  "type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "yoga_types", ["teacher_id"], name: "index_yoga_types_on_teacher_id", using: :btree

end
