require 'dashing'
require 'active_support'
require 'active_support/all'
require 'time'

# Verbose logging in Octokit
# Octokit.configure do |config|
#   config.middleware.response :logger unless ENV['RACK_ENV'] == 'production'
# end

Octokit.auto_paginate = true

ENV['SINCE'] ||= '12.months.ago.beginning_of_month'
ENV['SINCE'] = ENV['SINCE'].to_datetime.to_s rescue eval(ENV['SINCE']).to_s

configure do
  set :auth_token, 'n3q48nerbkjvVFSAo9yh34libco9y23qjbGGhflkjdhs98y2398kj'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
