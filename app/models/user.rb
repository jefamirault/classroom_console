class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :enrollments
  has_many :sections, through: :enrollments
  has_many :courses, through: :sections

  def to_s
    self.name
  end
end
