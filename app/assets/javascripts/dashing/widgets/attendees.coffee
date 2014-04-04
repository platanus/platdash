class Dashing.Attendees extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
    # Handle incoming data
    # You can access the html node of this widget with `@node`
    # Example: $(@node).fadeOut().fadeIn() will make the node flash each time data comes in.
    $node = $(@node)

    $.each data.attendees, (_, attendee) ->
        console.log caca, attendee
    #   $attendee_div = $node.find '#' + _crawler.name
