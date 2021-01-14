json.extract! course, :id, :name, :sis_id, :is_active, :course_length, :created_at, :updated_at
json.url course_url(course, format: :json)
