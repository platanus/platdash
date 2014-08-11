require 'json'
require 'time'
require 'octokit'

SCHEDULER.every '1h', :first_in => 0 do |job|
  repo_name = 'platanus/angular-restmod'

	@client = Octokit::Client.new(
    :login => ENV['GITHUB_LOGIN'],
    :access_token => ENV['GITHUB_OAUTH_TOKEN']
  )

  repo = @client.repository(repo_name)

  subscribers = @client.subscribers(repo_name)

	send_event('restmod', {
		stargazers: repo.stargazers_count,
		watchers: subscribers.count,
    forks: repo.forks,
    open_issues: repo.open_issues
	})
end
