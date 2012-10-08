require "rubygems"
require "bundler/setup"
require 'sinatra/base'
require 'nokogiri'
require 'net/http'
require 'uri'
require 'haml'
require 'json'
require 'coffee_script'
require 'digest/md5'

class WarpedFeed
  URL = "http://vanswarpedtour.com/dates"

  def download
    uri = URI.parse(URL)
    response = Net::HTTP.get_response(uri)
    response.body
  end

  def parse
    html_doc = Nokogiri::HTML(download)

    html_doc.css('tr.event-row.past').map do |el|
      #require 'debugger'; debugger
      date = el.at_css('.date a').children.text
      location = el.at_css('.location').children[3].text

      { :date => date, :location => location }
    end
  end
end

class WeatherAPI
  KEY = "ed542c31f010d6e0"

  def load_from_cache(url)
    begin
      digest = Digest::MD5.hexdigest(url)
      File.read("tmp/#{digest}.txt")
    rescue
      nil 
    end
  end

  def save_to_cache(url, json)
    digest = Digest::MD5.hexdigest(url)
    fp = File.new("tmp/#{digest}.txt", "w")
    fp << json
    fp.close
  end

  def get_from_http(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    response.body
  end

  def get_json(url)
    json = nil
    json = load_from_cache(url) if ENV['WEATHER_CACHING']
    json ||= get_from_http(url)
    save_to_cache(url, json) if ENV['WEATHER_CACHING']
    JSON.parse(json)
  end

  def conditions(state, city)
    underscore_city_name = city.tr(' ', '_')
    get_json("http://api.wunderground.com/api/#{KEY}/conditions/q/#{state}/#{underscore_city_name}.json")
  end
end

class HowCrapyWasIt < Sinatra::Base
  get '/' do
    locations = WarpedFeed.new.parse[0,5]
    haml :index, :locals => { :locations => locations }
  end

  get '/application.js' do
    content_type "text/javascript"
    coffee :application 
  end

  get '/weather.json' do
    api = WeatherAPI.new
    city, state = params[:city].split(',')
    cities = api.conditions(state.strip, city.strip)
    content_type :json
    cities.to_json
  end
end


