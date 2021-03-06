require 'net/http'
require 'uri'

current_valuation = 0

SCHEDULER.every '2m', :first_in => 1 do
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

  # Send the event
  send_event('bitcoin', { current: current_valuation, difference: change.abs, last: last_valuation })

end
