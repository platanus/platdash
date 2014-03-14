require 'httpclient'

Dashing.scheduler.every '20s', :first_in => 4 do

  client = HTTPClient.new
  status = client.get_content('http://pricing.platan.us/api/status.json')
  status = JSON.parse status

  Dashing.send_event('pricing', status)

end
