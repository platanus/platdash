# encoding: UTF-8

require 'google/api_client'
require 'date'
require 'time'
# require 'pry'

# Update these to match your own apps credentials
service_account_email = ENV['GOOGLE_SERVICE_ACCOUNT_EMAIL'] # Email of service account
key_file = ENV['GOOGLE_SERVICE_PK_FILE'] # File containing your private key
key_secret = ENV['GOOGLE_SERVICE_KEY_SECRET'] # Password to unlock private key
calendarID = ENV['WORLDCUP_CALENDAR'] # Calendar ID.
next_event_time = ENV['NEXT_EVENT_TIME'] || '14:00' # Time to start showing the next event
next_event_timezone = ENV['NEXT_EVENT_TIMEZONE'] # Time zone to parse the next event time in
myTeam = ENV['WORLDCUP_MY_TEAM']

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
SCHEDULER.every '60s', :first_in => 4 do |job|

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the calendar API
  calendar = client.discovered_api('calendar','v3')

  # Start and end dates
  startDate = DateTime.now + 43.days
  # startDate = Date.parse("2014-06-13T20:00:00Z").rfc3339
  endDate = Date.parse("2014-07-15").rfc3339

  # Get the events
  events = client.execute(:api_method => calendar.events.list,
                          :parameters => {
                                :calendarId => calendarID,
                                :timeMin => startDate,
                                :timeMax => endDate,
                                :orderBy => 'startTime',
                                :singleEvents => true
                              }
                          )

  # The worldcup matches
  matches = events.data.items;

    # binding.pry
  # Set the event if there is one found
  if events.data.items.count > 0

    # Next Match
    nextMatch = matches.first
    nextMatches = matches.select {|match| match.start.dateTime == nextMatch.start.dateTime}

    # My team matches
    myTeamMatches = matches.select {|match| match.summary.match(/#{myTeam}/i)}

    # http://img.fifa.com/images/flags/3/chi.png

    #
  end

  # Update the dashboard
  send_event('worldcup', {
    next_matches: nextMatches,
    my_team_matches: myTeamMatches
  })
end
