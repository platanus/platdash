require 'mixpanel_client'
require 'date'
 
root = ::File.dirname(__FILE__)
require ::File.join(root, "..", "..", 'lib', 'mixpanel_config')
require ::File.join(root, "..", "..", 'lib', 'mixpanel_event_number')
 
Dashing.scheduler.every '70s', :first_in => 10 do |job|
  Dashing.send_event('qh_orders', {
    value: mixpanel_event_number(
      event_name: "Checkout Success",
      interval:(Time.now.seconds_since_midnight/60 + Time.now.formatted_offset.to_i*60).to_i,
      unit:"minute")
  })
end

Dashing.scheduler.every '35s', :first_in => 6 do |job|
  Dashing.send_event('qh_visits', {
    current: mixpanel_event_number(
      event_name: "Search",
      interval:(Time.now.seconds_since_midnight/60 + Time.now.formatted_offset.to_i*60).to_i,
      unit:"minute")
  })
end