class Dashing.Pricing extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
  	$node = $(@node)

    # set the background color for each crawler depending on the error_rate
  	$.each data.crawlers, (_, _crawler) ->
  		$crawler_div = $node.find '#' + _crawler.name
  		hue = 0.3 - 0.3 * (if _crawler.error_rate > 20 then 20 else _crawler.error_rate) / 20
  		rgb = HSVtoRGB hue, 0.8, 0.8
  		_crawler.color = 'background: rgb('+rgb.r+','+rgb.g+','+rgb.b+');'

Batman.mixin Batman.Filters,
  secToHours: (number) ->
    (number / 60 / 60).toFixed(2);

