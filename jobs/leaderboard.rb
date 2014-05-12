require 'json'
require 'time'
require 'octokit'
require 'active_support'
require 'active_support/core_ext'
require File.expand_path('../../lib/helper', __FILE__)
require File.expand_path('../../lib/leaderboard', __FILE__)

SCHEDULER.every '1h', :first_in => 0 do |job|
	backend = GithubBackend.new()
	leaderboard = Leaderboard.new(backend)

	weighting = {
		'issues_opened'=>5,
		'issues_closed'=>5,
		'pulls_opened'=>10,
		'pulls_closed'=>5,
		'pulls_merged'=>20,
		'pulls_comments'=>1,
		'upstream_pulls_opened'=>15,
		'upstream_pulls_closed'=>5,
		'upstream_pulls_merged'=>30,
		'issues_comments'=>1,
		'commits_comments'=>1,
		'commits_additions'=>0.005,
		'commits_deletions'=>0.005,
		'commits'=>20
	}
	weighting = weighting.merge(
		ENV['LEADERBOARD_WEIGHTING'].split(',').inject({}) {|c,pair|c.merge Hash[*pair.split('=')]}
	) if ENV['LEADERBOARD_WEIGHTING']

	days_interval = 30
	date_since = days_interval.days.ago.utc
	date_until = Time.now.to_datetime
	data = leaderboard.get(
		:period=>'month',
		:orgas=>(ENV['ORGAS'].split(',') if ENV['ORGAS']),
		:repos=>(ENV['REPOS'].split(',') if ENV['REPOS']),
		:repos_exclude=>(ENV['REPOS_EXCLUDE'].split(',') if ENV['REPOS_EXCLUDE']),
		:teams=>(ENV['TEAMS'].split(',') if ENV['TEAMS']),
		:repos_type=>(ENV['REPOS_TYPE'] if ENV['REPOS_TYPE']),
		:since=>date_since, # not using ENV because 'since' is likely higher than needed
		:weighting=>weighting,
		:limit=>12,
		:date_interval=>days_interval.days
	)

	# Filter the actors to show only the ones in the defined team
	team_members = backend.get_team_members(ENV['MEMBERS_FROM_TEAM']) if ENV['MEMBERS_FROM_TEAM']

	# Contributors
	actors = data[:actors]
	actors = actors.select {|actor| team_members.include?(actor[0]) } if team_members
	actors = actors.map do |actor|
		actor_github_info = backend.user(actor[0])

		if actor_github_info['avatar_url']
			actor_icon = actor_github_info['avatar_url'] + "&s=32"
		elsif actor_github_info['email']
			actor_icon = "http://www.gravatar.com/avatar/" + Digest::MD5.hexdigest(actor_github_info['email'].downcase) + "?s=24"
		else
			actor_icon = ''
		end

		trend = GithubDashing::Helper.trend_percentage(
			actor[1]['previous_score'],
			actor[1]['current_score']
		)

		{
			name: actor[0],
			fullname: actor_github_info['name'],
			icon: actor_icon,
			current_score: actor[1]['current_score'],
			current_score_desc: 'Score from current %d days period. %s' % [days_interval, actor[1]['current_desc']],
			previous_score: actor[1]['previous_score'],
			previous_score_desc: 'Score from previous %d days period. %s' % [days_interval, actor[1]['previous_desc']],
			trend: trend,
			trend_class: GithubDashing::Helper.trend_class(trend),
			github: actor_github_info
		}
	end if actors

	# Repositories
	repos = data[:repos]
	repos = repos.map do |repo|
		trend = GithubDashing::Helper.trend_percentage(
			repo[1]['previous_score'],
			repo[1]['current_score']
		)

		{
			name: repo[0],
			current_score: repo[1]['current_score'],
			current_score_desc: 'Score from current %d days period. %s' % [days_interval, repo[1]['current_desc']],
			previous_score: repo[1]['previous_score'],
			previous_score_desc: 'Score from previous %d days period. %s' % [days_interval, repo[1]['previous_desc']],
			trend: trend,
			trend_class: GithubDashing::Helper.trend_class(trend)
		}
	end if repos

	send_event('leaderboard_actors', {
		items: actors,
		date_since: date_since.strftime("#{date_since.day.ordinalize} %b"),
		date_until: date_until.strftime("#{date_until.day.ordinalize} %b"),
	})

	send_event('leaderboard_repos', {
		items: repos,
		date_since: date_since.strftime("#{date_since.day.ordinalize} %b"),
		date_until: date_until.strftime("#{date_until.day.ordinalize} %b"),
	})
end
