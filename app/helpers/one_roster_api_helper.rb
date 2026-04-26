require 'net/http'
require 'uri'
require 'json'

module OneRosterApiHelper
  def oneroster_api_path
    AdminSetting.first.oneroster_api_path
  end

  def oneroster_key
    AdminSetting.first.oneroster_key
  end

  def oneroster_secret
    AdminSetting.first.oneroster_secret
  end

  def oneroster_scope
    AdminSetting.first.oneroster_scope
  end

  def oneroster_authenticate
    raw_uri = oneroster_api_path
    puts "Authenticating to OneRoster: #{raw_uri}"
    uri = URI.parse(raw_uri)

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.basic_auth(oneroster_key, oneroster_secret)

    body_params = { grant_type: 'client_credentials' }
    body_params[:scope] = oneroster_scope if oneroster_scope.present?
    request.body = URI.encode_www_form(body_params)

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
  end
end
