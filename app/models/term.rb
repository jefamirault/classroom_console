class Term < ApplicationRecord
  belongs_to :school_year
  has_many :sections
  has_many :courses, -> {distinct}, through: :sections
  has_many :logs, as: :loggable
  has_many :events, through: :logs
  has_many :sync_profiles
  def self.sync_terms
    puts "Syncing Terms..."
    result1 = Term.refresh_sis_terms
    result2 = Term.match_canvas_terms

    description = ""
    if result1[:updated_terms].any?
      description << "Detected start/end times for #{result1[:updated_terms].size} terms. "
    end
    if result2[:detected_terms].any?
      description << "Detected #{result2[:detected_terms].size} Canvas terms. "
    end
    if result2[:created_terms].any?
      description << "Created #{result2[:created_terms].size} Canvas terms. "
    end
    description.strip!
    if result1[:updated_terms].any?
      event = Event.make 'Sync Terms', description
      result1[:updated_terms].each do |t|
        Log.create event_id: event.id, loggable_id: t.id, loggable_type: 'Term'
      end
    end
  end

  extend OnApiHelper

  def self.get_sis_terms
    on_api_get 'schoolinfo/term/', "&schoolYear=#{AdminSetting.first.sis_school_year}"
  end

  def self.refresh_sis_terms
    result = { updated_terms: [] }
    json = JSON.parse Term.get_sis_terms.body
    json.each do |term_json|
      term = Term.find_by_sis_id term_json['DurationId'].to_i
      if term && term.start.nil? && term.end.nil?
        term.start = DateTime.strptime(term_json['BeginDate'], '%m/%d/%Y %I:%M %p')
        term.end = DateTime.strptime(term_json['EndDate'], '%m/%d/%Y %I:%M %p')
        if term.save
          result[:updated_terms] << term
        end
      end
    end

    Term.where(start: nil, end: nil).each do |term|
      next unless term.name.include? ' Full Year'
      year = term.name[0..10]
      term1 = Term.find{|t| t.name.include?('1st Semester') && t.name.include?(year)}
      term2 = Term.find{|t| t.name.include?('2nd Semester') && t.name.include?(year)}
      term.start = term1.start
      term.end = term2.end
      if term.save
        result[:updated_terms] << term
      end
    end

    result
  end

  extend CanvasApiHelper

  def self.match_canvas_terms(terms_json = Term.get_canvas_terms['enrollment_terms'])
    result = { created_terms: [], detected_terms: [] }
    Term.all.each do |term|
      # match terms by name
      match = terms_json.find {|t| t['name'] == term.name}
      # TODO: what if there are multiple canvas terms with the same name?
      if match
        if term.canvas_id.nil?
          if term.update canvas_id: match['id']
            result[:detected_terms] << term
          end
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
        response = canvas_api_post "accounts/#{AdminSetting.first.account_id}/terms", body
        if response['id']
          term.canvas_id = response['id']
          if term.save
            result[:created_terms] << term
          end
        end
      end
    end
    result
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
    canvas_api_get_json "accounts/#{AdminSetting.first.account_id}/terms"
  end
  def current?
    if !self.start.nil? && !self.end.nil?
      self.start <= Date.today && Date.today <= self.end
    else
      nil
    end
  end

  def status
    if self.current?
      'Active'
    elsif self.start && self.start > Date.today
      'Not Started'
    elsif self.end && self.end < Date.today
      'Concluded'
    else
      ''
    end
  end
end
