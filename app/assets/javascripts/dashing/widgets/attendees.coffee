class Dashing.Attendees extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
    @set('summaryMessage', if data.tomorrow_event then @get('tomorrowMessage') else @get('todayMessage') )
