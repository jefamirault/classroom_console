require 'net/http'
require 'uri'
require_relative 'export_helper'
require 'logger'

module OnApiHelper
  ON_API_URL = ENV['ON_API_URL']
  ON_API_KEY = ENV['ON_API_KEY']
  ON_API_SECRET = ENV['ON_API_SECRET']

  include ExportHelper

  def on_authenticate
    raw_uri = "#{ON_API_URL}/authentication/login"
    puts "Authenticating to ON API: #{raw_uri}"
    uri = URI.parse(raw_uri)
    request = Net::HTTP::Post.new(uri)

    request["Content-Type"] = 'application/json'

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    request.body = {
        username: ON_API_KEY,
        password: ON_API_SECRET
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    # Responds with access token. Expires after 20 minutes without being used.
    response
  end


  def on_api_token(options = {})
    last_token = read_object 'timed_token'
    if last_token && last_token[:expire] > Time.now
      puts "Reusing existing ON API token. Expires at #{last_token[:expire]}" if options[:verbose]
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
      puts "Created new ON API token. Expires at #{timed_token[:expire]}" if options[:verbose]
      write_object timed_token, 'timed_token'
      token
    end
  end

  def force_new_on_api_token(options = {})
    time = Time.now
    response = on_authenticate
    token = JSON.parse(response.body)['Token']
    timed_token = {
      token: token,
      expire: time + 20*60 # 20 minutes
    }
    puts "Created new ON API token. Expires at #{timed_token[:expire]}" if options[:verbose]
    write_object timed_token, 'timed_token'
    token
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

  def on_api_get(route, parameters = nil, options = {})
    uri = URI.parse("#{ON_API_URL}/#{route}?t=#{on_api_token}#{parameters}")
    puts "GET #{ON_API_URL}/#{route}?t=*#{parameters}..." if options[:verbose]

    header = { 'Content-Type': 'application/json' }

  # Create the HTTP objects

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri, header)

  # Send the request
    response = http.request(request)

    response
  end

  def on_api_get_json(route, parameters = nil)
    JSON.parse on_api_get(route, parameters).body
  end
end