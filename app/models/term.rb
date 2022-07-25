class Term < ApplicationRecord

  has_many :sections


  def self.get_sis_values(sections_json, courses_json)
    sections_json.map do |s|
      course_id = s['OfferingId']
      course = courses_json.find {|c| c['OfferingId'] == course_id }
      # ignore sections without courses
      if course.nil?
        next
      end

      # all courses should have a length of 1 or 2 (semesters)
      # course length is 2 -> Full year course (Fall + Spring Semester)
      # course length is 1 -> Single semester course (Fall OR Spring OR Summer)
      # ESY (Extended School Year) may be used for some summer coursework
      course_length = course['CourseLength']
      if course_length == 1
        s['Duration']['SchoolYearLabel'] + ' ' + s['Duration']['Name']
      elsif course_length == 2
        s['Duration']['SchoolYearLabel'] + " Full Year"
      end
    end.uniq.reject(&:nil?).map {|term| { name: term, created_at: Time.now, updated_at: Time.now }}
  end

  extend OnApiHelper

  def self.get_sis_terms
    on_api_get 'schoolinfo/term/', "&schoolYear=#{ENV['SIS_SCHOOL_YEAR']}"
  end

  def self.refresh_sis_terms
    json = JSON.parse Term.get_sis_terms.body
    json.each do |term_json|
      term = Term.find_by_sis_id term_json['DurationId']
      if term
        term.start = DateTime.strptime(term_json['BeginDate'], '%m/%d/%Y %I:%M %p')
        term.end = DateTime.strptime(term_json['EndDate'], '%m/%d/%Y %I:%M %p')
        term.save
      end
    end

    Term.where(start: nil, end: nil).each do |term|
      next unless term.name.include? ' Full Year'
      year = term.name[0..10]
      term1 = Term.find{|t| t.name.include?('1st Semester') && t.name.include?(year)}
      term2 = Term.find{|t| t.name.include?('2nd Semester') && t.name.include?(year)}
      term.start = term1.start
      term.end = term2.end
      term.save
    end
  end

  extend CanvasApiHelper

  def self.match_canvas_terms(terms_json = Term.get_canvas_terms['enrollment_terms'])
    Term.all.each do |term|
      # match terms by name
      match = terms_json.find {|t| t['name'] == term.name}
      # TODO: what if there are multiple canvas terms with the same name?
      if match
        if term.canvas_id.nil?
          term.update({
            canvas_id: match['id'],
            start: match['start_at'] ? match['start_at'].to_datetime : nil,
            end: match['end_at'] ? match['end_at'].to_datetime : nil
          })
        else
        #  TODO: overwrite or ignore existing canvas_id?
        end
      else
        # Canvas should ignore summer courses
        next if term.name.include? 'Summer'
        #  create term in Canvas
        body = {
          enrollment_term: {
            name: term.name,
            start_at: term.start - Time.zone_offset('EST'),
            end_at: term.end - Time.zone_offset('EST')
          }
        }.to_json
        response = canvas_api_post "accounts/#{ENV['ACCOUNT_ID']}/terms", body
        if response['id']
          term.canvas_id = response['id']
          term.save
        end
      end
    end
  end

  def to_s
    self.name
  end

  def active?
    self.start < Time.now && Time.now < self.end
  end

  def ended?
    self.end < Time.now
  end

  def self.get_canvas_terms
    canvas_api_get_json "accounts/#{ENV['ACCOUNT_ID']}/terms"
  end

end
