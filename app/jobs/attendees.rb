# encoding: UTF-8

require 'google/api_client'
require 'date'
require 'time'
require 'digest/md5'

# Update these to match your own apps credentials
service_account_email = ENV['GOOGLE_SERVICE_ACCOUNT_EMAIL'] # Email of service account
key_file = ENV['GOOGLE_SERVICE_PK_FILE'] # File containing your private key
key_secret = ENV['GOOGLE_SERVICE_KEY_SECRET'] # Password to unlock private key
calendarID = ENV['ATTENDEE_CALENDAR'] # Calendar ID.
eventId = ENV['ATTENDEE_EVENT'] # Event ID
defaultImg = ENV['DEFAULT_GRAVATAR'] # Url to image to show as default when no gravatar
next_event_time = ENV['NEXT_EVENT_TIME'] || '14:00' # Time to start showing the next event
next_event_timezone = ENV['NEXT_EVENT_TIMEZONE'] # Time zone to parse the next event time in

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
  show_tomorrow_event = Time.now >= Time.parse(next_event_time + (next_event_timezone || ""))
  startDate = !show_tomorrow_event ? Date.today.rfc3339 : Date.today.next_day.rfc3339
  endDate = !show_tomorrow_event ? Date.today.next_day.rfc3339 : Date.today.next_day(2).rfc3339

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

  # Set the event if there is one found
  if events.data.items.count > 0
    # Get the first matching event
    calendar_event = events.data.items.first

    # Get only the attedees that had accepted
    accepted_attendees = calendar_event.attendees.select {|attendee| attendee.responseStatus == 'accepted'}

    # Prepare the attendees object
    accepted_attendees = accepted_attendees.map do |attendee|
      email = attendee.email.downcase

      # Force additional guests property
      attendee['additionalGuests'] = attendee['additionalGuests'] || 0

      # Set the gravatar url
      hash = Digest::MD5.hexdigest(email)
      attendee[:gravatar] = "http://www.gravatar.com/avatar/#{hash}"
      attendee[:gravatar] += "?default=#{defaultImg}" if defaultImg
      attendee
    end

    # Event hash to pass to dashing
    event = {
      title: calendar_event.summary,
      attendees: accepted_attendees,
      total_attendees: accepted_attendees.reduce(accepted_attendees.length){|r, v| r + v['additionalGuests']},
    }
  end

  # Update the dashboard
  Dashing.send_event('attendees', {
    event: event,
    tomorrow_event: show_tomorrow_event
  })
end
