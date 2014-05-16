require 'google/api_client'
require 'digest/md5'
require 'google_drive'

class SpreadsheetFetcher
  def initialize
      service_account_email = ENV['GOOGLE_SERVICE_ACCOUNT_EMAIL'] # Email of service account
      key_file = ENV['GOOGLE_SERVICE_PK_FILE'] # File containing your private key
      key_secret = ENV['GOOGLE_SERVICE_KEY_SECRET'] # Password to unlock private key

      # Get the Google API client
      @client = Google::APIClient.new(:application_name => 'Google Spreadsheet With Dashing',
        :application_version => '0.0.1')

      # Load your credentials for the service account
      if not key_file.nil? and File.exists? key_file
        key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
      else
        key = OpenSSL::PKey::RSA.new ENV['GOOGLE_SERVICE_PK'], key_secret
      end

      @client.authorization = Signet::OAuth2::Client.new(
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => 'https://spreadsheets.google.com/feeds',
        :issuer => service_account_email,
        :signing_key => key)
  end

  def fetch(_spreadsheet_key)
    token = @client.authorization.fetch_access_token!
    session = GoogleDrive.login_with_oauth token["access_token"]
    return session.spreadsheet_by_key(_spreadsheet_key)
  end

end