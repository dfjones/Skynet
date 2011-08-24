util = require 'util'
request = require 'request'

actions = null

init = (params) ->
  actions = params.actions

commands =
  weather:

    match: (m) ->
      m.indexOf('!weather') is 0

    run: (message) ->
      search = message.substring(9).trim()
      if search is ""
        search = "10013"

      queryWeather = (zip) ->
        util.log 'Fetching weather for: ' + search
        query = "select item from weather.forecast where location = '#{ zip }'"
        uri = "http://query.yahooapis.com/v1/public/yql?format=json&q=#{ encodeURIComponent(query) }"
        util.log uri
        request({ uri: uri }, (error, response, body) ->
          json = JSON.parse body
          item = json.query.results.channel.item
          if not item.condition
            response = item.title
          else
            response = "#{ item.title }: #{ item.condition.temp } degrees and #{ item.condition.text }"
          actions.send response
        )

      if not parseInt(search)
        # probably not a zipcode...try to figure out the zipcode
        query = "select * from geo.placefinder where text=\"#{ search }\""
        uri = "http://query.yahooapis.com/v1/public/yql?format=json&q=#{ encodeURIComponent(query) }"
        util.log uri
        request({ uri: uri }, (error, response, body) ->
          json = JSON.parse body
          if not json.query.results
            actions.send "There is no weather in #{ search }"
          else
            result = json.query.results.Result
            zip = result.uzip
            queryWeather(zip)
        )
      else
        queryWeather(search)

  introduce:

    match: (m) ->
      m.indexOf('meet Skynet') isnt -1

    run: (message) ->
      i = message.indexOf('meet')
      name = message.substring(0, i).trim()
      actions.send "Hello #{ name }, I'm Skynet!"

module.exports = { commands: commands, init: init }
