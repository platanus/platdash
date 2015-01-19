require 'httpclient'

SCHEDULER.every '5m', :first_in => 1 do

  client = HTTPClient.new
  status = client.get_content('http://www.madbill.com/api/stats')
  status = JSON.parse status

  send_event('madbill', {
    current: status['debtor_appuser_1w']})

end
