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

SCHEDULER.every '10m', :first_in => 0 do |job|

  developers = remoteObject('http://platan.us/team.json?filter=developers')
  calendars = developers.map do |dev| {id: dev['calendar']} end

  client.authorization.fetch_access_token!

  calendar = client.discovered_api('calendar','v3')

  response = client.execute(
    :api_method => calendar.freebusy.query,
    :body => JSON.dump(
      {
        :timeMin => Date.today.rfc3339,
        :timeMax => (Date.today + 7).rfc3339,
        :timeZone => GeneralKeyValue.instance.get(:occupation_timezone),
        :items => calendars
      }

      ),
    :headers => {'Content-Type' => 'application/json'})

  developers.each do |dev|
    dev[:avatar] = "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(dev['email'])}"
    dev[:busy_hours] = 0
    occupation = response.data.calendars.to_hash[dev['calendar']]
    unless occupation.nil?
      occupation['busy'].each do |session|
        dev[:busy_hours] += (Time.parse(session['end']) - Time.parse(session['start'])) / 1.hour
      end
      weekly = GeneralKeyValue.instance.get("occupation_#{dev['slug']}_weekly_hours".to_sym).to_i
      if weekly == 0
        weekly = GeneralKeyValue.instance.get(:occupation_default_weekly_hours).to_i || 40
      end
      dev[:percent] = (dev[:busy_hours] * 100 / weekly).round

      today_events = client.execute(
        :api_method => calendar.events.list,
        :parameters => {
          :calendarId => dev['calendar'],
          :timeMin => DateTime.current.rfc3339,
          :timeMax => (Date.today + 1).rfc3339,
          :maxResults => 10,
          :singleEvents => true,
          :orderBy => "startTime"
        },
        :headers => {'Content-Type' => 'application/json'})

      dev[:events] = today_events.data.items.map {|a| a.summary}.reject {|a| a == "Almuerzo"}.uniq.first(2).join(" | ")
    end
  end

  developers.sort_by! {|d| -d[:percent]}
  send_event('occupation', {items: developers})
end
