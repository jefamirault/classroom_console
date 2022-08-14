class Log < ApplicationRecord
  belongs_to :event
  belongs_to :loggable, polymorphic: true
end