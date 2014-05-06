require 'net/http'
require 'uri'

current_valuation = 0

SCHEDULER.every '20s', :first_in => 4 do
  last_valuation = current_valuation
  # Go get the prices from bitstamp open api
  uri = URI.parse('https://www.bitstamp.net/api/ticker/')
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == "https"
    http.use_ssl=true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  # Parse the resulting json from bitstamp's response
  obj = JSON.parse(response.body)

  # Prepare the event information
  current_valuation = obj['last'].to_i
  change = current_valuation - last_valuation
  arrow = (change > 0)? 'fa fa-arrow-up green' : 'fa fa-arrow-down red'

  # Send the event
  send_event('bitcoin', { current: current_valuation, difference: change.abs, arrow: arrow, prefix:'$'})


end
