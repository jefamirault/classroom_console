class Quarantine < ApplicationRecord
  belongs_to :quarantinable, polymorphic: true
end