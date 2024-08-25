class SyncProfile < ApplicationRecord
  belongs_to :user
  belongs_to :term
  has_many :subscriptions

  def get_teacher_sections
    response = on_api_get '/academics/TeacherSection', "&schoolYear=#{AdminSetting.sis_school_year}&userID=#{user.sis_id}"
    raise 'Error' if response.code != '200'
    sections_json = JSON.parse response.body
    sections_json.map {|s| "SIS_ID: #{s['Id']} - #{s['Name']} #{s['SectionIdentifier']}"}
  end
  def get_teacher_sections_json
    response = on_api_get '/academics/TeacherSection', "&schoolYear=#{AdminSetting.sis_school_year}&userID=#{user.sis_id}"
    raise 'Error' if response.code != '200'
    sections_json = JSON.parse response.body
    sections_json
  end

  def generate_subscriptions
    section_ids = get_teacher_sections_json.select{|s| s['Id'] == s['LeadSectionId']}.map do |s|
      s['Id']
    end
    # Ignore non-lead sections, e.g. the second semester of a full-year course

    sections_json = get_teacher_sections_json

    created_subscriptions = section_ids.map do |sid|
      s = Subscription.create sync_profile_id: self.id, section_sis_id: sid
      preexisting_section = Section.find_by_sis_id(s.section_sis_id)
      if s && preexisting_section
        s.section = preexisting_section
        s.save
      else
        #   TODO: Create section if one does not exist
      end
      s
    end
    created_subscriptions
  end

  def sync_now
    self.subscriptions.where(enabled: true).each &:sync
  end
end