#!/usr/bin/env ruby
require 'net/http'
require 'uri'

# Check whether a server is responding
# you can set a server to check via http request or ping
#
# server options:
# name: how it will show up on the dashboard
# url: either a website url or an IP address (do not include https:// when usnig ping method)
# method: either 'http' or 'ping'
# if the server you're checking redirects (from http to https for example) the check will
# return false

servers = [
  {name: 'kross', url: 'http://kross.platan.us'},
  {name: 'szot', url: 'http://szot.platan.us'}
]

STATES = {
  "unmonitored" =>        { icon: "fa fa-warning",        color: "red" },
  "starting" =>           { icon: "fa fa-refresh",        color: "yellow" },
  "stopping" =>           { icon: "fa fa-warning",        color: "red" },
  "restarting" =>         { icon: "fa fa-refresh",        color: "yellow" },
  "up" =>                 { icon: "fa fa-thumbs-up",      color: "green" },
  "down" =>               { icon: "fa fa-warning",        color: "red" },
}

SCHEDULER.every '60s', :first_in => 10 do |job|

  statuses = Array.new

  # check status for each server
  servers.each do |server|


    begin
      uri = URI.parse("#{server[:url]}/api/short?filter=all")
      http = Net::HTTP.new(uri.host, 65093)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
    rescue
    end

    # Parse the resulting json from bitstamp's response
    obj = JSON.parse(response.body)
    result = obj['result']['subtree']

    result = result.map do |app|
      app["is_up"] = app["states"].keys.none? {|a| a != "up"}

      app["states"] = app["states"].map do |state, value|
        {
          state: state,
          process_count: value,
          icon: STATES[state][:icon],
          color: STATES[state][:color]
        }
      end
      app
    end

    statuses.push({server: server[:name], applications: result})
  end

#   end
  p statuses

#   # print statuses to dashboard
  send_event('server_status', {items: statuses})
end
