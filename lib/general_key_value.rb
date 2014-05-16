require 'singleton'
require File.expand_path('../spreadsheet_fetcher.rb', __FILE__)

class GeneralKeyValue
  include Singleton

  def initialize
    @dictionary = {}
    update
  end

  def get(_key)
    @dictionary[_key]
  end

  def set(_dictionary)
    @dictionary = _dictionary
  end

  def update
    fetcher = SpreadsheetFetcher.new
    w = fetcher.fetch('1XJ_DtBtfHbglF7deOZJGyNy0C7qYOj92W_iJm60xYxU').worksheets[0]
    dict = {}
    w.rows.each do |row|
      dict[row[0].to_sym] = row[1]
    end
    @dictionary = dict
  end
end

