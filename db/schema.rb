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

ActiveRecord::Schema[7.0].define(version: 2025_07_21_210427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admin_settings", force: :cascade do |t|
    t.string "canvas_path"
    t.string "canvas_access_token"
    t.string "on_api_path"
    t.string "on_api_username"
    t.string "on_api_key"
    t.string "on_api_secret"
    t.integer "account_id"
    t.string "sis_school_year"
    t.integer "sis_level_num"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "allow_on_api_read", default: false
    t.boolean "allow_on_api_write", default: false
    t.boolean "allow_canvas_api_read", default: false
    t.boolean "allow_canvas_api_write", default: false
  end

  create_table "assignments", force: :cascade do |t|
    t.integer "sis_id"
    t.integer "section_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name"
    t.integer "sis_id"
    t.boolean "is_active"
    t.integer "course_length"
    t.boolean "sync_course"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sections_count", default: 0, null: false
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.boolean "enrolled_in_canvas"
    t.float "grade"
    t.integer "role"
    t.integer "last_grade_change_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "label"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grade_changes", force: :cascade do |t|
    t.integer "enrollment_id"
    t.float "old_value"
    t.float "new_value"
    t.datetime "time", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "previous_change_id"
    t.integer "next_change_id"
  end

  create_table "logs", force: :cascade do |t|
    t.integer "event_id"
    t.integer "loggable_id"
    t.string "loggable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "quarantines", force: :cascade do |t|
    t.datetime "end"
    t.integer "quarantinable_id"
    t.string "quarantinable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "school_years", force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sis_id"
    t.index ["sis_id", "name"], name: "index_school_years_on_sis_id_and_name", unique: true
  end

  create_table "sections", force: :cascade do |t|
    t.string "name"
    t.integer "sis_id"
    t.integer "course_id"
    t.integer "canvas_id"
    t.integer "canvas_course_id"
    t.integer "term_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_sync", precision: nil
    t.integer "enrollments_count", default: 0, null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "section_sis_id"
    t.integer "section_id"
    t.integer "sync_profile_id"
    t.boolean "enabled"
    t.boolean "sis_enrollments"
    t.boolean "maintain_canvas_section"
    t.boolean "post_canvas_grades"
  end

  create_table "sync_profiles", force: :cascade do |t|
    t.integer "user_id"
    t.integer "term_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "school_year_id"
  end

  create_table "tenant_variables", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "terms", force: :cascade do |t|
    t.string "name"
    t.integer "canvas_id"
    t.datetime "start", precision: nil
    t.datetime "end", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sis_id"
    t.integer "school_year_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "sis_id"
    t.string "name"
    t.boolean "active"
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "canvas_id"
    t.boolean "login_enabled", default: false, null: false
    t.integer "enrollments_count", default: 0, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["sis_id"], name: "index_users_on_sis_id", unique: true
  end

end
