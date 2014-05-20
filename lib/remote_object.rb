require 'uri'
require 'net/http'
require 'json'

def remoteObject(_json_url)

  uri = URI.parse(_json_url)
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == "https"
    http.use_ssl=true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)

  # Parse the resulting json from bitstamp's response
  return JSON.parse(response.body)

end