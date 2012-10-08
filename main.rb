require "rubygems"
require "bundler/setup"
require 'sinatra/base'
require 'nokogiri'
require 'net/http'
require 'uri'

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

class HowCrapyWasIt < Sinatra::Base
  get '/' do
    WarpedFeed.new.parse.inspect
  end
end


