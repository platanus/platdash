# :first_in sets how long it takes before the job is first run. In this case, it is run immediately

#TODO : go and ask Google whats the onda loco for the next week.

# encoding: UTF-8

require 'google/api_client'
require 'digest/md5'

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
  :scope => 'https://www.googleapis.com/auth/calendar.readonly',
  :issuer => service_account_email,
  :signing_key => key)

md5 = Digest::MD5.new

calendars = [
  # {
  #   name: "J.I.Donoso",
  #   id: "juan.ignacio@platan.us",
  #   avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('juan.ignacio@platan.us')}"
  # },
  # {
  #   name:"A. Feuerhake",
  #   id: "agustin@platan.us",
  #   avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('agustin@platan.us')}",
  #   weekly: 40
  # },
  # {
  #   name:"J. Bunzli",
  #   id: "platan.us_76q7fudikh18gu54mb2apvnsc4@group.calendar.google.com",
  #   avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('jaime@platan.us')}",
  #   weekly: 40
  # },
  {
    name:"L. Segovia",
    id: "platan.us_js98bml0b21d2nu09h58ktp7pg@group.calendar.google.com",
    avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('leandro@platan.us')}"
  }#,
  # {
  #   name:"E. Blanco",
  #   id: "platan.us_76q7fudikh18gu54mb2apvnsc4@group.calendar.google.com",
  #   avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('emilio@platan.us')}"
  # },
  # {
  #   name:"J. Garcia",
  #   id: "platan.us_76q7fudikh18gu54mb2apvnsc4@group.calendar.google.com",
  #   avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('julio@platan.us')}"
  # },
  # {
  #   name:"F. Campos",
  #   id: "platan.us_76q7fudikh18gu54mb2apvnsc4@group.calendar.google.com",
  #   avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('felipe@platan.us')}"
  # },
  # {
  #   name:"I. Baixas",
  #   id: "platan.us_76q7fudikh18gu54mb2apvnsc4@group.calendar.google.com",
  #   avatar: "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('ignacio@platan.us')}"
  # }
]

SCHEDULER.every '1m', :first_in => 0 do |job|

  client.authorization.fetch_access_token!

  calendar = client.discovered_api('calendar','v3')

  response = client.execute(
    :api_method => calendar.freebusy.query,
    :body => JSON.dump(
      {
        :timeMin => Date.today.rfc3339,
        :timeMax => (Date.today + 7).rfc3339,

        :timeZone => "UTC-04:00",
        :items => calendars
      }

      ),
    :headers => {'Content-Type' => 'application/json'})


calendars.each do |cal|
  cal[:busy_hours] = 0
  occupation = response.data.calendars.to_hash[cal[:id]]
  occupation['busy'].each do |session|
    cal[:busy_hours] += (Time.parse(session['end']) - Time.parse(session['start'])) / 1.hour
  end
  cal[:percent] = ((cal[:busy_hours] * 100 / (cal[:weekly] || 40)).round).to_s + "%"
end

# response.data.calendars.to_hash.each do |name,cal|
#   busy_hours = 0
#   cal['busy'].each do |session|
#     busy_hours += (Time.parse(session['end']) - Time.parse(session['start'])) / 1.hour
#   end
#   items.push({name: name, busy_hours: busy_hours})
# end

  send_event('occupation', {items: calendars})
end