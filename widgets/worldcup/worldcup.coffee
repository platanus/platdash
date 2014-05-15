class Dashing.Worldcup extends Dashing.Widget

  ready: ->
    @refresh()

  onData: (data) ->
    @refresh(data)

  refresh: (data) ->
    nextTitle = if @get('next_matches').length > 1 then "Next Matches" else "Next Match"
    @set('next-title', nextTitle)

    # Set a global next match formatted time
    nextMatch = @get('next_matches')[0]
    @set('next-match-time', @formatDate(nextMatch.start, nextMatch.end))

    # Set the formatted time for each of my team matches
    match.start.formatted = @formatDate(match.start, match.end) for match in @get('my_team_matches')
    #
    true

  formatDate: (startDate, endDate) ->
    nowMoment = moment()
    startMoment = moment(new Date startDate.dateTime)
    endMoment = moment(new Date endDate.dateTime)
    if nowMoment > startMoment and nowMoment < endMoment
      "LIVE"
    else if nowMoment > endMoment
      "FINISHED"
    else
      moment(new Date startDate.dateTime).fromNow()
