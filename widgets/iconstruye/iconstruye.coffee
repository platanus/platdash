class Dashing.Iconstruye extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
    $node = $(@node)

    # set the main error indicator color.
    main_hue = if query_count > 0 then query_error_count / query_count else 0.0
    main_hue = 0.3 - main_hue
    main_rgb = HSVtoRGB main_hue, 0.8, 0.8

    data.error_color = 'color: rgb(' + main_rgb.r + ',' + main_rgb.g + ',' + main_rgb.b + ');'

    # set the background color for each crawler depending on the error_rate
    crawler_array = []
    $.each data.crawlers, (_name, _crawler) ->
      _crawler.name = _name
      hue = if _crawler.runs > 0 then 0.3 * _crawler.errors / _crawler.runs else 0.0
      hue = 0.3 - hue
      rgb = HSVtoRGB hue, 0.8, 0.8
      _crawler.color = 'background: rgb(' + rgb.r + ',' + rgb.g + ',' + rgb.b + ');'
      crawler_array.push _crawler

    @set 'crawlers', crawler_array
    # data.crawlers = crawler_array
