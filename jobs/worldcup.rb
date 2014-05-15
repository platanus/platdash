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

flags = {
  "Brazil" => 'bra',
  "Croatia" => 'cro',
  "Mexico" => 'mex',
  "Cameroon" => 'cmr',
  "Spain" => 'esp',
  "Netherlands" => 'ned',
  "Chile" => 'chi',
  "Australia" => 'aus',
  "Colombia" => 'col',
  "Greece" => 'gre',
  "Ivory Coast" => 'civ',
  "Japan" => 'jpn',
  "Uruguay" => 'uru',
  "Costa Rica" => 'crc',
  "England" => 'eng',
  "Italy" => 'ita',
  "Switzerland" => 'sui',
  "Ecuador" => 'ecu',
  "France" => 'fra',
  "Honduras" => 'hon',
  "Argentina" => 'arg',
  "Bosnia and Herzegovina" => 'bih',
  "Iran" => 'irn',
  "Nigeria" => 'nig',
  "Germany" => 'ger',
  "Portugal" => 'por',
  "Ghana" => 'gha',
  "USA" => 'usa',
  "Belgium" => 'bel',
  "Algeria" => 'alg',
  "Russia" => 'rus',
  "South Korea" => 'kor'
}

# Start the scheduler
SCHEDULER.every '60s', :first_in => 4 do |job|

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the calendar API
  calendar = client.discovered_api('calendar','v3')

  # Start and end dates
  startDate = (DateTime.now - 2.hours).rfc3339 #+ 32.days
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

  matches = matches.each do |match|

    match[:teams] = match.summary.match(/(.*) v (.*)/i)[1,2].map do |team|
      next if not flags[team]
      {
        flag_small: "http://img.fifa.com/images/flags/2/#{flags[team]}.png",
        flag_mid: "http://img.fifa.com/images/flags/3/#{flags[team]}.png",
        flag_large: "http://img.fifa.com/images/flags/4/#{flags[team]}.png",
        name: team,
        code: flags[team].upcase
      }
    end
  end

  # Set the event if there is one found
  if events.data.items.count > 0

    # Next Match
    nextMatch = matches.first
    nextMatches = matches.select {|match| match.start.dateTime == nextMatch.start.dateTime}

    # My team matches
    myTeamMatches = matches.select do |match|
      if match.summary.match(/#{myTeam}/i)
        match[:my_team_opponent] = match[:teams].find{|team| not team[:name].match(/#{myTeam}/i) }
        true
      else
        false
      end
    end
  end

  # Update the dashboard
  send_event('worldcup', {
    next_matches: nextMatches,
    my_team_matches: myTeamMatches
  })
end
