# :first_in sets how long it takes before the job is first run. In this case, it is run immediately

#TODO : go and ask Google whats the onda loco for the next week.

# encoding: UTF-8

require 'google/api_client'
require 'digest/md5'
require 'google_drive'

# Update these to match your own apps credentials
service_account_email = ENV['GOOGLE_SERVICE_ACCOUNT_EMAIL'] # Email of service account
key_file = ENV['GOOGLE_SERVICE_PK_FILE'] # File containing your private key
key_secret = ENV['GOOGLE_SERVICE_KEY_SECRET'] # Password to unlock private key

# Get the Google API client
client = Google::APIClient.new(:application_name => 'Google Calendar Attendee Widget',
  :application_version => '0.0.1')

# Load your credentials for the service account
if not key_file.nil? and File.exists? key_file
  key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
else
  key = OpenSSL::PKey::RSA.new ENV['GOOGLE_SERVICE_PK'], key_secret
end

client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://spreadsheets.google.com/feeds',
  :issuer => service_account_email,
  :signing_key => key)


SCHEDULER.every '1m', :first_in => 0 do |job|

  restaurants = []

  token = client.authorization.fetch_access_token!

  session = GoogleDrive.login_with_oauth token["access_token"]

  w = session.spreadsheet_by_key("1AoqoTn93HFefh8JiXEq63LPppa3Cj6vSMlNdYXR6gPs").worksheets[0]

  for row in 2..w.num_rows
    if w[row,2]
      restaurants.push(
        {
          name: w[row,1],
          date: w[row,2],
          days: (Date.today - Date.parse(w[row,2])).round
        })
      restaurants.last[:face] = (restaurants.last[:days].to_i > 5) ? 'fa fa-frown-o' : 'fa fa-cutlery'
    end
  end

  # puts restaurants.inspect
  send_event('waiting_restos', {items: restaurants})
end
