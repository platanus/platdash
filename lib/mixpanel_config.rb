class MixPanelConfiguration
 
  def self.config
    {
      api_key: ENV['MIXPANEL_APIKEY'],
      api_secret: ENV['MIXPANEL_SECRETKEY']
    }
  end
 
end