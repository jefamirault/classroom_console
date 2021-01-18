module TermsHelper
  def format_datetime(datetime)
    if datetime
      datetime.strftime '%m/%d/%Y at %-I:%M%P'
    else
      nil
    end
  end

  def format_date(date)
    if date
      date.strftime '%m/%d/%Y'
    else
      nil
    end
  end
end
