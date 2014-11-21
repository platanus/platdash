require 'httpclient'

SCHEDULER.every '5m', :first_in => 4 do

  client = HTTPClient.new
  status = client.get_content('http://www.sorteoamigosecreto.com/api/stats')
  status = JSON.parse status

  send_event('amigosecreto', status)

end
