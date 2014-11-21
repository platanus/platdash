class Dashing.Amigosecreto extends Dashing.Widget

  @accessor 'difference', ->
    if @get('raffles')
      current = parseInt(@get('raffles'))
      last = parseInt(@get('today_last_year_raffles'))

      parseFloat(current / last * 100).toFixed(2)
    else
      ""

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->

