class Dashing.Occupation extends Dashing.Widget

  ready: ->

  onData: (data) ->
    $node = $(@node)

    # set the background color for each dev depending on the error_rate
    $.each data.items, (_, _dev) ->
        $dev_div = $node.find '#' + _dev.slug
        hue = 0.3 * _dev.percent / 100
        rgb = HSVtoRGB hue, 0.8, 0.8
        _dev.style = 'background: rgb('+rgb.r+','+rgb.g+','+rgb.b+'); width: '+_dev.percent+'%;'
