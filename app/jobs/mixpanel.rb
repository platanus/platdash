require 'mixpanel_client'
require 'date'
 
root = ::File.dirname(__FILE__)
require ::File.join(root, "..", "..", 'lib', 'mixpanel_config')
require ::File.join(root, "..", "..", 'lib', 'mixpanel_event_number')
 
Dashing.scheduler.every '30s', :first_in => 4 do |job|
  Dashing.send_event('qh_orders', {
    value: mixpanel_event_number(
      event_name: "Checkout Success",
      interval:(Time.now.in_time_zone("Santiago").seconds_since_midnight/60).to_i,
      unit:"minute")
  })
end

Dashing.scheduler.every '15s', :first_in => 3 do |job|
  Dashing.send_event('qh_visits', {
    current: mixpanel_event_number(
      event_name: "Search",
      interval:(Time.now.in_time_zone("Santiago").seconds_since_midnight/60).to_i,
      unit:"minute")
  })
end