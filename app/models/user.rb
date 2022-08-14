include CanvasApiHelper

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :enrollments
  has_many :sections, through: :enrollments
  has_many :courses, through: :sections
  has_many :logs, as: :loggable
  has_many :events, through: :logs

  ACCOUNT_ID = 1


  def to_s
    self.name
  end

  def self.sync_canvas_users
    puts "Syncing Canvas Users..."
    result = { detected_canvas_users: [], created_canvas_users: [] }
    description = ""

    result[:detected_canvas_users] += User.refresh_canvas_users[:detected_canvas_users]
    result[:created_canvas_users] += User.create_missing_canvas_users[:created_canvas_users]

    description << "Detected #{result[:detected_canvas_users].count} existing Canvas users. " if result[:detected_canvas_users].any?
    description << "Created #{result[:created_canvas_users].count} new Canvas users." if result[:created_canvas_users].any?
    description.strip!

    if result[:detected_canvas_users].any? || result[:created_canvas_users].any?
      event = Event.make 'Sync Canvas Users', description
      result[:detected_canvas_users].each do |u|
        Log.create event_id: event.id, loggable_id: u.id, loggable_type: 'User'
      end
      result[:created_canvas_users].each do |u|
        Log.create event_id: event.id, loggable_id: u.id, loggable_type: 'User'
      end
    end

    result
  end

  def self.refresh_canvas_users(canvas_users = User.request_canvas_users)
    result = { detected_canvas_users: [] }

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
        if user.save validate: false
          result[:detected_canvas_users] << user
        end
      end
    end
    result
  end

  def self.refresh_sis_emails(json = User.request_sis_emails)
    puts "Checking for new email addresses..."
    result = { updated_users: [] }
    json.each do |j|
      user = User.find_by_sis_id j['UserID']
      if user && user.email.nil?
        user.email = j['EMail']
        if user.save
          result[:updated_users] << user
        end
      end
    end
    if result[:updated_users].any?
      event = Event.make 'Refresh SIS Emails', "Detected new email address for #{result[:updated_users].count} users."
      result[:updated_users].each do |u|
        Log.create event_id: event.id, loggable_id: u.id, loggable_type: 'User'
      end
    end
    result
  end

  extend OnApiHelper

  def self.request_sis_rosters
    response = on_api_get ''
  end

  def self.request_sis_emails
    on_api_get_json "list/#{ENV['EMAIL_LIST_ID']}"
  end

  extend CanvasApiHelper

  def self.request_canvas_users
    canvas_api_get_paginated "accounts/#{ACCOUNT_ID}/users"
  end

  def self.create_missing_canvas_users
    result = { created_canvas_users: [] }
    users = User.where(canvas_id: nil).where.not(email: nil).where.not(sis_id: nil)

    users.each do |u|
      increment = u.create_in_canvas
      if increment[:created_canvas_user]
        result[:created_canvas_users] << increment[:created_canvas_user]
      end
    end
    result
  end

  def create_in_canvas
    raise 'Cannot create. Canvas ID is already present for User.' if self.canvas_id
    raise 'Cannot create Canvas user without email.' if self.email.nil?

    result = { created_canvas_user: nil }

    body = {
      user: {
        name: self.name
      },
      pseudonym: {
        unique_id: self.email.downcase,
        sis_user_id: self.sis_id,
      #  Google's auth provider id assigned by Canvas: 141
        authentication_provider_id: 141      }
    }.to_json

    response = canvas_api_post "accounts/1/users", body

    if response['id']
      if self.update canvas_id: response['id']
        result[:created_canvas_user] = self
      end
    else
      description = "ERROR: Could not create Canvas user: #{self} #{response}"
      # don't log duplicate errors in the same day
      if Event.where(description: description).select{|e| e.created_at > 1.day.ago }.empty?
        event = Event.make "Create Canvas User", "ERROR: Could not create Canvas user: #{self} #{response}"
        Log.create event_id: event.id, loggable_id: self.id, loggable_type: 'User'
      end
    end

    result
  end

  protected

  def password_required?
    self.login_enabled ? super : false
  end
end
