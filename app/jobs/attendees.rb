# encoding: UTF-8

require 'google/api_client'
require 'date'
require 'digest/md5'

# Update these to match your own apps credentials
service_account_email = ENV['GOOGLE_SERVICE_ACCOUNT_EMAIL'] # Email of service account
key_file = ENV['GOOGLE_SERVICE_PK_FILE'] # File containing your private key
key_secret = ENV['GOOGLE_SERVICE_KEY_SECRET'] # Password to unlock private key
calendarID = ENV['ATTENDEE_CALENDAR'] # Calendar ID.
eventId = ENV['ATTENDEE_EVENT'] # Event ID

# Get the Google API client
client = Google::APIClient.new(:application_name => 'Platanus Dashboard',
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

# Start the scheduler
Dashing.scheduler.every '60s', :first_in => 4 do |job|

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the calendar API
  calendar = client.discovered_api('calendar','v3')

  # Start and end dates
  startDate = Date.today.rfc3339
  endDate = Date.today.next_day.rfc3339

  # Get the events
  events = client.execute(:api_method => calendar.events.instances,
                          :parameters => {
                                :calendarId => calendarID,
                                :eventId => eventId,
                                :maxResults => 1,
                                :timeMin => startDate,
                                :timeMax => endDate
                              }
                          )

  lunch = events.data.items.first
  attendees = lunch.attendees

  accepted = attendees.select {|attendee| attendee.responseStatus == 'accepted'}

  accepted = accepted.map do |attendee|
    hash = Digest::MD5.hexdigest(attendee.email.downcase)
    attendee[:gravatar] = "http://www.gravatar.com/avatar/#{hash}"
    attendee
  end

  # Update the dashboard
  Dashing.send_event('attendees', { attendees: accepted })
end
