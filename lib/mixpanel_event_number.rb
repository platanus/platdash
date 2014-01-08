def mixpanel_client
  @mixpanel_client ||= Mixpanel::Client.new(MixPanelConfiguration.config)
end
 
# Public: Returns number of occurrences of the event
# of the date range of [T-num_days, T] where T is today's date
# options - The Hash options used to query MixPanel:
#           :event_name  - The String name of the event.
#           :type - The String analysis type you would like to get data for. Available options are "general", "unique", "average" (optional).
#           :num_days - The Integer number of days to look back (optional)
#           :property - The String if filtering by property, name of the property. Must provide :value (optional)
#           :value - The String if filtering by property, value of the property. Must provide :property (optional)
# https://mixpanel.com/docs/api-documentation/data-export-api
#
# Examples
#
#    mixpanel_event_number(event_name: "Created Gist", property: "level", value: "private")
#    mixpanel_event_number(event_name: "Created Gist")
#    mixpanel_event_number(event_name: "Created Gist", type: "unique")
 
def mixpanel_event_number(options)

  property, value = options[:property], options[:value]
 
  unless (property && value) || (!property && !value)
    raise "Must specify both 'property' and 'value' or none"
  end
 
  if [TrueClass, FalseClass].include?(value.class)
    raise "As of Aug 7, 2013, MixPanel has a bug with querying boolean values\nPlease use number_for_event_using_export until that's fixed"
  end
 
  event_name = options[:event_name]
 
  unless event_name
    raise "Event name must be provided"
  end
 
  type = options[:type] || "general" #MixPanel API uses the term 'general' to mean 'total'
 
  unless ["unique", "general", "average"].include? type
    raise "Invalid type #{type}"
  end
 
  num_days = options[:num_days] ||30
  interval = options[:interval] || "day"
 
  mixpanel_options = {
    type: type,
    unit: interval,
    interval: num_days,
    limit: 5,
  }
 
  if property && value
    mixpanel_endpoint = "events/properties/"
    mixpanel_options.merge!({
      event: event_name,
      values: [value],
      name: property
    })
  else
    mixpanel_endpoint = "events/"
    mixpanel_options.merge!({
      event: [event_name]
    })
  end
 
  data = mixpanel_client.request(mixpanel_endpoint, mixpanel_options)
  total_for_events(data)
end
 
def total_for_events(data)
  counts_per_property = data["data"]["values"].collect do |c, values|
    values.collect { |k, v| v }.inject(:+)
  end
 
  #now, calculate grand total
  counts_per_property.inject(:+)
end
 
###########################
 
def number_for_event_using_export(event_name, property, value, num_days = 30)
 
  # TODO:
  # MixPanel doesn't understand boolean values for properties
  # There is an open ticket, but for now, there is a work around to use export API
  # https://mixpanel.com/docs/api-documentation/exporting-raw-data-you-inserted-into-mixpanel
  to_date = Date.today
  from_date = to_date - num_days
 
  data = mixpanel_client.request('export', {
    event: [event_name],
    from_date: from_date.to_s,
    to_date: to_date.to_s,
    where: "boolean(properties[\"#{property}\"]) == #{value} ",
  })
 
  data.count
end