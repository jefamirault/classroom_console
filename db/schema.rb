# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_02_12_170051) do

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
    t.boolean "sync_grades"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.boolean "enrolled_in_canvas"
    t.float "grade"
    t.integer "role"
    t.integer "last_grade_change_id"
  end

  create_table "grade_changes", force: :cascade do |t|
    t.integer "enrollment_id"
    t.float "old_value"
    t.float "new_value"
    t.datetime "time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "previous_change_id"
    t.integer "next_change_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "name"
    t.integer "sis_id"
    t.integer "course_id"
    t.integer "canvas_id"
    t.integer "canvas_course_id"
    t.integer "term_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "sync_grades"
    t.datetime "last_sync"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.text "email"
    t.integer "user_id"
    t.boolean "subscribed"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tenant_variables", force: :cascade do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "terms", force: :cascade do |t|
    t.string "name"
    t.integer "canvas_id"
    t.datetime "start"
    t.datetime "end"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.integer "sis_id"
    t.string "name"
    t.boolean "active"
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "canvas_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
