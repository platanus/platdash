class Dashing.DebtorRestos extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
    # Handle incoming data
    # You can access the html node of this widget with `@node`
    # Example: $(@node).fadeOut().fadeIn() will make the node flash each time data comes in.

Batman.mixin Batman.Filters,
  numberWithDots: (number) ->
    number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")