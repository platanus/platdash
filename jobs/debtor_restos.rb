require 'httpclient'

SCHEDULER.every '20m', :first_in => 2 do
  client = HTTPClient.new
  debtors = client.get_content('http://www.quehambre.cl/api/debtors?count=5')
  debtors = JSON.parse debtors
  debtors = debtors['data']
  send_event('debtor_restos', {debtors: debtors})
end
