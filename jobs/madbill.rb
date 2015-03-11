require 'httpclient'

SCHEDULER.every '5m', :first_in => 0 do

  client = HTTPClient.new
  status = client.get_content('http://www.madbill.pow/api/stats')
  status = JSON.parse status

  send_event('madbill', status)

end
