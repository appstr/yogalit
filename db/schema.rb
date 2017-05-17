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

ActiveRecord::Schema.define(version: 20170513233342) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "favorite_teachers", force: :cascade do |t|
    t.integer  "student_id"
    t.integer  "teacher_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "favorite_teachers", ["student_id"], name: "index_favorite_teachers_on_student_id", using: :btree
  add_index "favorite_teachers", ["teacher_id"], name: "index_favorite_teachers_on_teacher_id", using: :btree

  create_table "interview_booked_times", force: :cascade do |t|
    t.integer   "teacher_id"
    t.date      "interview_date"
    t.tstzrange "time_range"
    t.string    "teacher_timezone"
    t.boolean   "teacher_cancelled"
    t.boolean   "completed"
    t.datetime  "created_at",        null: false
    t.datetime  "updated_at",        null: false
  end

  add_index "interview_booked_times", ["teacher_id"], name: "index_interview_booked_times_on_teacher_id", using: :btree

  create_table "payments", force: :cascade do |t|
    t.integer  "student_id"
    t.integer  "teacher_id"
    t.float    "sales_tax"
    t.float    "price_without_tax"
    t.float    "total_price"
    t.float    "yogalit_tax"
    t.float    "yogalit_fee_amount"
    t.float    "teacher_payout_amount"
    t.string   "transaction_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "payments", ["student_id"], name: "index_payments_on_student_id", using: :btree
  add_index "payments", ["teacher_id"], name: "index_payments_on_teacher_id", using: :btree

  create_table "student_reported_yoga_sessions", force: :cascade do |t|
    t.integer  "teacher_id"
    t.integer  "student_id"
    t.integer  "yoga_session_id"
    t.string   "description"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "student_reported_yoga_sessions", ["student_id"], name: "index_student_reported_yoga_sessions_on_student_id", using: :btree
  add_index "student_reported_yoga_sessions", ["teacher_id"], name: "index_student_reported_yoga_sessions_on_teacher_id", using: :btree
  add_index "student_reported_yoga_sessions", ["yoga_session_id"], name: "index_student_reported_yoga_sessions_on_yoga_session_id", using: :btree

  create_table "students", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "students", ["user_id"], name: "index_students_on_user_id", using: :btree

  create_table "teacher_booked_times", force: :cascade do |t|
    t.integer   "teacher_id"
    t.integer   "student_id"
    t.date      "session_date"
    t.tstzrange "time_range"
    t.integer   "duration"
    t.string    "student_timezone"
    t.string    "teacher_timezone"
    t.datetime  "created_at",       null: false
    t.datetime  "updated_at",       null: false
  end

  add_index "teacher_booked_times", ["student_id"], name: "index_teacher_booked_times_on_student_id", using: :btree
  add_index "teacher_booked_times", ["teacher_id"], name: "index_teacher_booked_times_on_teacher_id", using: :btree

  create_table "teacher_emergency_cancels", force: :cascade do |t|
    t.integer  "teacher_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "teacher_emergency_cancels", ["teacher_id"], name: "index_teacher_emergency_cancels_on_teacher_id", using: :btree

  create_table "teacher_friday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_friday_time_frames", ["teacher_id"], name: "index_teacher_friday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_holidays", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "holiday_date_range"
    t.string    "description"
    t.datetime  "created_at",         null: false
    t.datetime  "updated_at",         null: false
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
    t.integer  "teacher_id"
    t.float    "thirty_minute_session"
    t.float    "sixty_minute_session"
    t.float    "ninety_minute_session"
    t.float    "sales_tax"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "teacher_price_ranges", ["teacher_id"], name: "index_teacher_price_ranges_on_teacher_id", using: :btree

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

  create_table "teacher_reported_yoga_sessions", force: :cascade do |t|
    t.integer  "teacher_id"
    t.integer  "student_id"
    t.integer  "yoga_session_id"
    t.string   "description"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "teacher_reported_yoga_sessions", ["student_id"], name: "index_teacher_reported_yoga_sessions_on_student_id", using: :btree
  add_index "teacher_reported_yoga_sessions", ["teacher_id"], name: "index_teacher_reported_yoga_sessions_on_teacher_id", using: :btree
  add_index "teacher_reported_yoga_sessions", ["yoga_session_id"], name: "index_teacher_reported_yoga_sessions_on_yoga_session_id", using: :btree

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

  create_table "teacher_tuesday_time_frames", force: :cascade do |t|
    t.integer   "teacher_id"
    t.int8range "time_range"
    t.datetime  "created_at", null: false
    t.datetime  "updated_at", null: false
  end

  add_index "teacher_tuesday_time_frames", ["teacher_id"], name: "index_teacher_tuesday_time_frames_on_teacher_id", using: :btree

  create_table "teacher_videos", force: :cascade do |t|
    t.integer  "teacher_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.datetime "video_updated_at"
  end

  add_index "teacher_videos", ["teacher_id"], name: "index_teacher_videos_on_teacher_id", using: :btree

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
    t.string   "paypal_email"
    t.integer  "average_rating",           limit: 8
    t.boolean  "is_searchable"
    t.boolean  "is_verified"
    t.boolean  "blacklisted"
    t.date     "unblacklist_date"
    t.boolean  "has_been_blacklisted"
    t.boolean  "blocked"
    t.boolean  "vacation_mode"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "profile_pic_file_name"
    t.string   "profile_pic_content_type"
    t.integer  "profile_pic_file_size"
    t.datetime "profile_pic_updated_at"
  end

  add_index "teachers", ["user_id"], name: "index_teachers_on_user_id", using: :btree

  create_table "user_messages", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "email"
    t.string   "subject"
    t.string   "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_messages", ["user_id"], name: "index_user_messages_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "teacher_or_student"
    t.boolean  "blacklisted"
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

  create_table "yoga_sessions", force: :cascade do |t|
    t.integer  "payment_id"
    t.integer  "teacher_id"
    t.integer  "student_id"
    t.integer  "teacher_booked_time_id"
    t.string   "opentok_session_id"
    t.boolean  "teacher_payout_made"
    t.boolean  "video_under_review"
    t.boolean  "video_reviewed"
    t.boolean  "teacher_cancelled_session"
    t.boolean  "student_requested_refund"
    t.boolean  "student_refund_given"
    t.integer  "yoga_type"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "yoga_sessions", ["payment_id"], name: "index_yoga_sessions_on_payment_id", using: :btree
  add_index "yoga_sessions", ["student_id"], name: "index_yoga_sessions_on_student_id", using: :btree
  add_index "yoga_sessions", ["teacher_booked_time_id"], name: "index_yoga_sessions_on_teacher_booked_time_id", using: :btree
  add_index "yoga_sessions", ["teacher_id"], name: "index_yoga_sessions_on_teacher_id", using: :btree

  create_table "yoga_types", force: :cascade do |t|
    t.integer  "teacher_id"
    t.integer  "type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "yoga_types", ["teacher_id"], name: "index_yoga_types_on_teacher_id", using: :btree

end
