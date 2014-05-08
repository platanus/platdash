class Dashing.Occupation extends Dashing.Widget

  ready: ->
    Dashing.debug_mode = true

  onData: (data) ->
    # Handle incoming data
    # You can access the html node of this widget with `@node`
    # Example: $(@node).fadeOut().fadeIn() will make the node flash each time data comes in.