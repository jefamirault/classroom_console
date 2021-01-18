class Term < ApplicationRecord

  def self.get_sis_values(sections_json, courses_json)
    sections_json.map do |s|
      course_id = s['OfferingId']
      course = courses_json.find {|c| c['OfferingId'] == course_id }
      if course.nil?
        next
      end
      course_length = course['CourseLength']
      if course_length == 1
        s['Duration']['SchoolYearLabel'] + ' ' + s['Duration']['Name']
      elsif course_length == 2
        s['Duration']['SchoolYearLabel'] + " Full Year"
      end
    end.uniq.reject(&:nil?).map {|term| { name: term, created_at: Time.now, updated_at: Time.now }}
  end

  def self.match_canvas_terms(terms_json)
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
      end
    end
  end

end
