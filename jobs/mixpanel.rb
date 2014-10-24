require 'mixpanel_client'
require 'date'

SCHEDULER.every '30s', :first_in => 4 do |job|
  send_event('qh_orders', {
    value: 120*mixpanel_event_number(
      event_name: "Checkout Success",
      interval:(Time.now.in_time_zone("Santiago").seconds_since_midnight/60).to_i,
      unit:"minute")
  })
end

SCHEDULER.every '15s', :first_in => 3 do |job|
  send_event('qh_visits', {
    current: 100*mixpanel_event_number(
      event_name: "Search",
      interval:(Time.now.in_time_zone("Santiago").seconds_since_midnight/60).to_i,
      unit:"minute")
  })
end
