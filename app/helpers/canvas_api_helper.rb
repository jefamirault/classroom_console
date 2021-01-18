require 'dotenv/load'
require 'net/http'
require 'uri'
require 'json'

module CanvasApiHelper

  CANVAS_URL = ENV['CANVAS_URL']
  ACCESS_TOKEN = ENV['ACCESS_TOKEN']
  # CANVAS_URL = ENV['CANVAS_TEST_URL']
  # ACCESS_TOKEN = ENV['ACCESS_TOKEN_TEST']



  # def canvas_api_get(route = 'courses', body = nil)
  #   uri = URI.parse("#{CANVAS_URL}/#{route}")
  def canvas_api_get(route = 'courses', parameters = nil, body = nil)
    uri = URI.parse("#{CANVAS_URL}/#{route}/#{parameters}")
    # puts "GET #{uri}..."
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ACCESS_TOKEN}"

    request["Content-Type"] = 'application/json'
    request.body = body

    req_options = {
        use_ssl: uri.scheme == "https"
    }
    response = nil
    begin
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue SocketError => msg
      puts msg
      raise "Failed to connect. Check internet connection."
    end

    # JSON.parse response.body
    response
  end

  def canvas_api_get_json(route, body = nil)
    response = canvas_api_get(route, body)
    JSON.parse response.body
  end

  def canvas_api_post(route, body, options = {})
    puts "POST #{CANVAS_URL}/#{route}..." unless options[:quiet]
    uri = URI.parse("#{CANVAS_URL}/#{route}")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ACCESS_TOKEN}"
    request["Content-Type"] = 'application/json'
    request.body = body

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    JSON.parse response.body
  end


  def canvas_api_post_response(route, body, options = {})
    puts "POST #{CANVAS_URL}/#{route}..." unless options[:quiet]
    uri = URI.parse("#{CANVAS_URL}/#{route}")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ACCESS_TOKEN}"
    request["Content-Type"] = 'application/json'
    request.body = body

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end

  def canvas_api_get_absolute(route, parameters = nil, body = nil)
    uri = URI.parse("#{route}/#{parameters}")
    # puts "GET #{uri}..."
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ACCESS_TOKEN}"

    request["Content-Type"] = 'application/json'
    request.body = body

    req_options = {
        use_ssl: uri.scheme == "https"
    }
    response = nil
    begin
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue SocketError => msg
      puts msg
      raise "Failed to connect. Check internet connection."
    end

    # JSON.parse response.body
    response
  end


  def canvas_api_put(route, body)
    puts "PUT #{CANVAS_URL}/#{route}..."
    uri = URI.parse("#{CANVAS_URL}/#{route}")
    request = Net::HTTP::Put.new(uri)
    request["Authorization"] = "Bearer #{ACCESS_TOKEN}"
    request["Content-Type"] = 'application/json'
    request.body = body

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    JSON.parse response.body

  end

  def canvas_api_delete(route, body)
    puts "DELETE #{CANVAS_URL}/#{route}..."
    uri = URI.parse("#{CANVAS_URL}/#{route}")
    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{ACCESS_TOKEN}"
    request["Content-Type"] = 'application/json'
    request.body = body

    req_options = {
        use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    JSON.parse response.body
  end



  ###############################################################
  # Page helper - Determine number of pages in paginated results
  ###############################################################

  # response['Link'] => page information, urls for first, current, next, last page
  def number_of_pages(link_info)
    last_page_link = link_info.split(',').last.split("\;").first
    start_index = last_page_link.index("?page=") + 6
    end_index = last_page_link.index("&per_page=") - 1
    last_page_link[start_index..end_index].to_i
  end

  def next_page_url(current_page_response)
    page_info = current_page_response['Link']
    if page_info.nil?
      raise 'Error fetching paged response.'
    end
    page_links = page_info.split(',')
    next_page = page_links.select {|l| l.index "rel=\"next\""}.first
    next_page ? next_page.split("\;").first[1..-2] : nil
  end

  def canvas_api_get_paginated(route)
    per_page = 100
    parameters = "?page=#{1}&per_page=#{per_page}"
    first_page = canvas_api_get route, parameters

    if first_page['status'] == '404 Not Found'
      puts "Route #{route} not found (404)"
      return nil
    end

    results = JSON.parse first_page.body

    next_url = next_page_url(first_page)
    until next_url.nil?
      next_page = canvas_api_get_absolute(next_url)
      results << JSON.parse(next_page.body)
      results.flatten!
      next_url = next_page_url(next_page)
    end
    results
  end

end