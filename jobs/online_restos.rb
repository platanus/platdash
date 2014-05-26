require 'httpclient'

SCHEDULER.every '20m', :first_in => 4 do

  client = HTTPClient.new
  status = client.get_content('http://quehambre.platan.us/api/stats.json')
  status = JSON.parse status
  stat = {current: status['clients']}
  send_event('online_restos', stat)
end
