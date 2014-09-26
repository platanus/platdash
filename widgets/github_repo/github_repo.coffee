class Dashing.GithubRepo extends Dashing.Widget

  ready: ->
    @currentIndex = 0
    @tweetsContainer = $(@node).find('.tweet')
    @nextCount()
    @startCarousel()

  onData: (data) ->
    clearInterval(@intervalInstance)
    @currentIndex = 0
    @tweetsContainer = $(@node).find('.tweet')
    @nextCount()
    @startCarousel()

  startCarousel: ->
    interval = $(@node).attr('data-interval')
    interval = "15" if not interval
    @intervalInstance = setInterval(@nextCount, parseInt( interval ) * 1000)

  nextCount: =>
    @tweetsContainer.fadeOut()
    @currentIndex = (@currentIndex + 1) % @tweets.length
    valueKey = @tweetsContainer.get(@currentIndex)
    $(valueKey).fadeIn()
