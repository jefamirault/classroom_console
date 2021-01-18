class GradeChange < ApplicationRecord
  belongs_to :enrollment
  has_one :user, through: :enrollment
  has_one :section, through: :enrollment

  def previous_change
    self.previous_change_id ? GradeChange.find(self.previous_change_id) : nil
  end
  alias_method :prev, :previous_change
  def next_change
    GradeChange.find self.next_change_id
  end
  alias_method :next, :next_change
end
