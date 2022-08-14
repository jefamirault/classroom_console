class Event < ApplicationRecord
  has_many :logs, dependent: :destroy

  def self.make(label, description)
    Event.create label: label, description: description
  end
end