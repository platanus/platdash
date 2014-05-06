require 'httpclient'

SCHEDULER.every '30s', :first_in => 4 do

  client = HTTPClient.new
  status = client.get_content('http://iconstruye-api.platan.us/api/status.json')
  status = JSON.parse status

  send_event('iconstruye', status)

end
