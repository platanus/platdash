require 'time'
require 'octokit'
require 'ostruct'
require 'json'
require 'active_support'
require 'active_support/core_ext'
# require 'raven'
require_relative 'event'
require_relative 'event_collection'

class GithubBackend

	attr_accessor :client, :logger

	def initialize(args={})
		@logger = Logger.new(STDOUT)
		@logger.level = Logger::DEBUG unless ENV['RACK_ENV'] == 'production'

		@client = Octokit::Client.new(
			:login => ENV['GITHUB_LOGIN'],
			:access_token => ENV['GITHUB_OAUTH_TOKEN']
		)

	end

	# Returns EventCollection
	def contributor_stats_by_author(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		events = GithubDashing::EventCollection.new
		self.get_repos(opts).each do |repo|
			# Can't limit timeframe
			begin
				stats = @client.contributors_stats(repo) || []
				if stats.respond_to? "each"
					stats.each do |stat|
						stat.weeks.each do |week|
							events << GithubDashing::Event.new({
								type: "commits_additions",
								key: stat.author.login,
								datetime: Time.at(week.w).to_datetime,
								value: week.a
							}) if week.a > 0
							events << GithubDashing::Event.new({
								type: "commits_deletions",
								key: stat.author.login,
								datetime: Time.at(week.w).to_datetime,
								value: week.d
							}) if week.d > 0
							events << GithubDashing::Event.new({
								type: "commits",
								key: stat.author.login,
								datetime: Time.at(week.w).to_datetime,
								value: week.c
							}) if week.c > 0
						end
					end
				end
			rescue Octokit::Error => exception
				# Raven.capture_exception(exception)
			end
		end

		return events
	end

	# Returns EventCollection
	def issue_comment_count_by_author(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		events = GithubDashing::EventCollection.new
		self.get_repos(opts).each do |repo|
			begin
				@client.issues_comments(repo, {:since => opts.since}).each do |issue|
					next if not issue.user
					events << GithubDashing::Event.new({
						type: "issues_comments",
						key: issue.user.login,
						datetime: issue.created_at.to_datetime
					})
				end
			rescue Octokit::Error => exception
				# Raven.capture_exception(exception)
			end
		end

		return events
	end

	# Returns EventCollection
	def pull_count_by_author(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		events = GithubDashing::EventCollection.new
		self.get_repos(opts).each do |repo|
			['open','closed'].each do |state|
				begin
					@client.pulls(repo, {:state => state, :since => opts.since}).each do |pull|
						state_desc = (state == 'open') ? 'opened' : 'closed'
						state_desc = 'merged' if state == 'closed' and pull.merged_at
						next if not pull.user
						events << GithubDashing::Event.new({
							type: "pulls_#{state_desc}",
							key: pull.user.login,
							datetime: pull.created_at.to_datetime
						})
					end
				rescue Octokit::Error => exception
					# Raven.capture_exception(exception)
				end
			end
		end

		return events
	end

	# Returns EventCollection
	def pull_comment_count_by_author(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		events = GithubDashing::EventCollection.new
		self.get_repos(opts).each do |repo|
			begin
				@client.pulls_comments(repo, {:since => opts.since}).each do |comment|
					next if not comment.user
					events << GithubDashing::Event.new({
						type: 'pulls_comments',
						key: comment.user.login,
						datetime: comment.created_at.to_datetime
					})
				end
			rescue Octokit::Error => exception
				# Raven.capture_exception(exception)
			end
		end

		return events
	end

	# Returns EventCollection
	def issue_count_by_author(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		events = GithubDashing::EventCollection.new
		self.get_repos(opts).each do |repo|
			['open','closed'].each do |state|
				begin
					issues = @client.issues(repo, {:since => opts.since,:state => state})
					state_desc = (state == 'open') ? 'opened' : 'closed'
					issues.each do |issue|
						next if not issue.user
						events << GithubDashing::Event.new({
							# TODO Attribute to closer, not to issue author
							# type: "issues_#{state_desc}",
							type: "issues_opened",
							key: issue.user.login,
							datetime: issue.created_at.to_datetime
						})
					end
				rescue Octokit::Error => exception
					# Raven.capture_exception(exception)
				end
			end
		end

		return events
	end

	# Returns EventCollection
	def upstream_pulls_count_by_author(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		opts.repos_type = 'fork'
		events = GithubDashing::EventCollection.new
		self.get_repos(opts, true).each do |repo|
			['open','closed'].each do |state|
				begin
					gh_repo = @client.repo(repo)
					gh_repo_branches = @client.branches(repo)

					next if not gh_repo.parent

					gh_repo_branches.each do |branch|
						pulls = @client.pulls(gh_repo.parent.full_name, {:state => state, :since => opts.since, :head => "#{repo.split("/")[0]}:#{branch.name}"})
						pulls = pulls.select {|pull|pull.created_at.to_datetime > opts.since.to_datetime}

						pulls.each do |pull|
							state_desc = (state == 'open') ? 'opened' : 'closed'
							state_desc = 'merged' if state == 'closed' and pull.merged_at

							events << GithubDashing::Event.new({
								type: "upstream_pulls_#{state_desc}",
								datetime: pull.created_at.to_datetime,
								key: pull.user.login,
							})
						end
					end
				rescue Octokit::Error => exception
					# Raven.capture_exception(exception)
				end
			end
		end

		return events
	end

	# Returns EventCollection
	def issue_count_by_status(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		events = GithubDashing::EventCollection.new
		offset = self.period_to_offset(opts.period)
		self.get_repos(opts).each do |repo|
			['open','closed'].each do |state|
				begin
					issues = @client.issues(repo, {:since => opts.since,:state => state})
					date_at = (state == 'open') ? 'created_at' : 'closed_at'
					issues = issues.select {|issue|issue[date_at].to_datetime > opts.since.to_datetime}

					# Reject all opened issues which are in fact pull requests, they shouldn't count against this negative value
					if state == 'open'
						issues = issues.reject {|issue|issue.pull_request.html_url}
					end

					state_desc = (state == 'open') ? 'opened' : 'closed'
					issues.each do |issue|
						events << GithubDashing::Event.new({
							type: "issue_count_#{state_desc}",
							datetime: issue.state == 'open' ? issue.created_at.to_datetime : issue.closed_at.to_datetime,
							key: issue.state,
							value: 1
						})
					end
				rescue Octokit::Error => exception
					# Raven.capture_exception(exception)
				end
			end
		end

		return events
	end

	# TODO Break up by actual status, currently not looking at closed_at date
	#
	# Returns EventCollection
	def pull_count_by_status(opts)
		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		events = GithubDashing::EventCollection.new
		offset = self.period_to_offset(opts.period)
		self.get_repos(opts).each do |repo|
			['open','closed'].each do |state|
				begin
					pulls = @client.pulls(repo, {:state => state, :since => opts.since})
					pulls = pulls.select {|pull|pull.created_at.to_datetime > opts.since.to_datetime}
					state_desc = (state == 'open') ? 'opened' : 'closed'
					pulls.each do |pull|
						events << GithubDashing::Event.new({
							type: "pull_count_#{state_desc}",
							datetime: pull.created_at.to_datetime,
							key: pull.state,
							value: 1
						})
					end
				rescue Octokit::Error => exception
					# Raven.capture_exception(exception)
				end
			end
		end

		return events
	end

	def user(name)
		@client.user(name)
	end

	def repo_stats(opts)
		# TODO
	end

	def get_repos(opts, force = false)
		if @repos and not force
			return @repos
		end

		opts = OpenStruct.new(opts) unless opts.kind_of? OpenStruct
		repos = []
		if opts.repos != nil
			repos = repos.concat(opts.repos)
		end
		if opts.teams != nil
			opts.teams.each do |team|
				team_org = team.split("/").first
				team_name = team.split("/").last
				begin
					team_id = @client.org_teams(team_org).find {|teams|teams.slug == team_name }.id
					repos = repos.concat(@client.team_repos(team_id, {:type => opts.repos_type || 'owner'}).map {|repo|repo.full_name})
				rescue Octokit::Error => exception
					# Raven.capture_exception(exception)
				end
			end
		end
		if opts.orgas != nil
			opts.orgas.each do |orga|
				begin
					repos = repos.concat(@client.org_repos(orga, {:type => opts.repos_type || 'owner'}).map {|repo|repo.full_name})
				rescue Octokit::Error => exception
					# Raven.capture_exception(exception)
				end
			end
		end
		if opts.repos_exclude != nil
			repos = repos - opts.repos_exclude
		end
		@repos = repos if not force
		return repos
	end

	def get_team_members(team)
		team_org = team.split("/").first
		team_name =	team.split("/").last
		members = []
		begin
			team_id = @client.org_teams(team_org).find {|teams|teams.slug == team_name }.id
			members = members.concat(@client.team_members(team_id).map {|member|member.login})
		rescue Octokit::Error => exception
			# Raven.capture_exception(exception)
		end
	end

	def period_to_offset(period)
		case period
		when 'day'
			offset = 10
		when 'month'
			offset = 7
		when 'year'
			offset = 4
		end
	end

end
