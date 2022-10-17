module Quarantinable
  extend ActiveSupport::Concern

  def create_quarantine!
    if quarantine.nil?
      Quarantine.create quarantinable: self
      reload
    end
  end

  def quarantined?
    if self.quarantine
      if quarantine.end.nil?
        true
      else
        Time.now < quarantine.end
      end
    else
      false
    end
  end
  alias_method :quarantined, :quarantined?

  def quarantine!
    create_quarantine!
  end

  def quarantined=(boolean)
    if boolean == true
      if quarantine.nil?
        quarantine!
      elsif quarantine && quarantine.end < Time.now
        quarantine.update end: nil
      else
        #  preserve quarantines end time, do nothing
      end
    elsif boolean == false
      if quarantined?
        quarantine.end = Time.now
      end
    else
      raise "Type Error. Quarantine must be assigned boolean value. #{boolean} does not evaluate to true or false."
    end
  end
end