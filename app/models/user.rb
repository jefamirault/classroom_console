class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :enrollments
  has_many :sections, through: :enrollments
  has_many :courses, through: :sections


  def to_s
    self.name
  end

  # TODO refactor into at least 2 methods
  def self.refresh_sis_users(rosters_json, emails_json)
    enrolled_users = rosters_json.map do |section|
      section['roster']
    end.flatten.uniq

    enrolled_users.each do |json|
      user_attributes = {
          sis_id: json['sis_id'],
          name: json['name'],
          # role: json['type'], TODO
          email: json['email']
      }
      # Create user if missing
      if !User.exists?(sis_id: json['sis_id'])
        u = User.new user_attributes
        u.save validate: false
      else
      #  Update user if any changes
      #  TODO
      end
    end

    # EMAILS
    updated = []
    User.all.each do |user|
      match = emails_json.select{|i| i['UserID'] == user.sis_id}
      if match.any?
        u = match.first
        email = u['EMail']
        user.assign_attributes email: email
        if user.changed?
          updated << [user, user.changes]
          user.save validate: false
        end
      end
    end
    puts "Updated #{updated.count} users."
  end

end
