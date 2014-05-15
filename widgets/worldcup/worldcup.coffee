class Dashing.Worldcup extends Dashing.Widget

  ready: ->
    @refresh()

  onData: (data) ->
    @refresh(data)

  refresh: (data) ->
    nextTitle = if @get('next_matches').length > 1 then "Next Matches" else "Next Match"
    @set('next-title', nextTitle)

    # Set a global next match formatted time
    @set('next-match-time', @formatDate(@get('next_matches')[0].start.dateTime))

    # Set the formatted time for each of my team matches
    match.start.formatted = @formatDate(match.start.dateTime) for match in @get('my_team_matches')
    #
    true

  formatDate: (date) ->
    moment(new Date date).fromNow()
