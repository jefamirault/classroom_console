class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :enrollments
  has_many :sections, through: :enrollments
  has_many :courses, through: :sections

  ACCOUNT_ID = 1


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


  def self.refresh_canvas_users(canvas_users = User.request_canvas_users)
    users_hash = Hash.new
    User.all.each do |user|
      users_hash[user.sis_id] = user
    end

    canvas_users.each do |u|
      # TODO: Sanitize string ids
      sis_id = u['sis_user_id'].to_i
      canvas_id = u['id'].to_i

      user = users_hash[sis_id]

      if user.nil?
        # skip Canvas user without SIS counterpart
        next
      end

      user.assign_attributes canvas_id: canvas_id
      if user.changed?
        puts "User updated: #{user}, #{user.changes}"
        user.save validate: false
      end

    end
  end


  extend OnApiHelper

  def self.request_sis_users
    response = on_api_get ''
  end

  extend CanvasApiHelper

  def self.request_canvas_users
    canvas_api_get_paginated "accounts/#{ACCOUNT_ID}/users"
  end


  protected

  def password_required?
    self.login_enabled ? super : false
  end
end
