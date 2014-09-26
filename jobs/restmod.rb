require 'json'
require 'time'
require 'octokit'
require 'twitter'

SCHEDULER.every '10m', :first_in => 0 do |job|
  repo_name = 'platanus/angular-restmod'
  search_term = URI::encode('restmod angular')

	@client = Octokit::Client.new(
    :login => ENV['GITHUB_LOGIN'],
    :access_token => ENV['GITHUB_OAUTH_TOKEN']
  )

  repo = @client.repository(repo_name)

  subscribers = @client.subscribers(repo_name)

  @twitterClient = Twitter::REST::Client.new do |config|
    config.consumer_key    = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  end

  tweets = @twitterClient.search("#{search_term}", :result_type => "recent").take(8)
  if tweets
    tweets.map! do |tweet|
      { name: tweet.user.name,
        handle: tweet.user.screen_name,
        body: tweet.text,
        avatar: tweet.user.profile_image_url.to_s,
        date: tweet.created_at.to_pretty
      }
    end
  end

	send_event('restmod', {
		stargazers: repo.stargazers_count,
		watchers: subscribers.count,
    forks: repo.forks,
    open_issues: repo.open_issues,
    tweets: tweets
	})
end
