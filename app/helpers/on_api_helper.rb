require 'net/http'
require 'uri'
require_relative 'export_helper'
require 'logger'

module OnApiHelper
  ON_API_URL = ENV['ON_API_URL']
  ON_API_USERNAME = ENV['ON_API_USERNAME']
  ON_API_PASSWORD = ENV['ON_API_PASSWORD']

  include ExportHelper

  def on_authenticate
    puts "Authenticating to ON API..."
    uri = URI.parse("#{ON_API_URL}/authentication/login")
    request = Net::HTTP::Post.new(uri)

    request["Content-Type"] = 'application/json'

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    request.body = {
        username: ON_API_USERNAME,
        password: ON_API_PASSWORD
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    # Responds with access token. Expires after 20 minutes without being used.
    response
  end

  def on_api_token
    last_token = read_object 'timed_token'
    if last_token && last_token[:expire] > Time.now
      # existing token has not expired
      last_token[:token]
    else
      # token expired, reauthenticate for new token
      time = Time.now
      response = on_authenticate
      token = JSON.parse(response.body)['Token']
      timed_token = {
          token: token,
          expire: time + 20*60 # 20 minutes
      }
      write_object timed_token, 'timed_token'
      token
    end
  end

  def on_api_post(route, token, body)
    # puts "POST #{ON_API_URL}/#{route}..."
    uri = URI.parse("#{ON_API_URL}/#{route}?t=#{token}")

    header = { 'Content-Type': 'application/json' }

  # Create the HTTP objects

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, header)

    request.body = body.to_json

  # Send the request
    response = http.request(request)

    response
  end

  def on_api_get(route, token, parameters = nil)
    uri = URI.parse("#{ON_API_URL}/#{route}?t=#{token}#{parameters}")
    # puts "GET #{ON_API_URL}/#{route}?t=*#{parameters}..."

    header = { 'Content-Type': 'application/json' }

  # Create the HTTP objects

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri, header)

  # Send the request
    response = http.request(request)

    response
  end

  def on_api_get_json(route, token, parameters = nil)
    JSON.parse on_api_get(route, token, parameters).body
  end
end