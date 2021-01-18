require 'rails_helper'

RSpec.describe Term, type: :model do
  it "determines unique values for SIS terms" do
    courses_json = [
        {
            'OfferingId' => 100,
            'Name' => 'Math S2',
            'CourseLength' => 1
        },
        {
            'OfferingId' => 101,
            'Name' => 'Math FY',
            'CourseLength' => 2
        }
    ]
    sections_json = [
        {
            'Name' => 'Math S2 - A Block',
            'OfferingId' => 100,
            'Duration' => {
                'SchoolYearLabel' => '2020-2021',
                'Name' => '2nd Semester'
            }
        },
        {
            'Name' => 'Math S2 - A Block',
            'OfferingId' => 100,
            'Duration' => {
                'SchoolYearLabel' => '2020-2021',
                'Name' => '1st Semester'
            }
        },
        {
            'Name' => 'Math FY - A Block',
            'OfferingId' => 101,
            'Duration' => {
                'SchoolYearLabel' => '2020-2021',
                'Name' => '1st Semester'
            }
        }
    ]
    terms = Term.get_sis_values sections_json, courses_json
    puts terms
    expect(terms.size).to eq 3
  end
end
