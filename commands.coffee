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
      search = message.substring 9
      util.log 'Fetching weather for: ' + search

      query = "select item from weather.forecast where location = #{ search }"
      uri = "http://query.yahooapis.com/v1/public/yql?format=json&q=#{ encodeURIComponent(query) }"
      util.log uri
      request({ uri: uri }, (error, response, body) ->
        json = JSON.parse body
        util.log body
        item = json.query.results.channel.item
        if not item.condition
          response = item.title
        else
          response = "#{ item.title }: #{ item.condition.temp } degrees and #{ item.condition.text }"

        actions.send response
      )

  introduce:

    match: (m) ->
      m.indexOf('meet SSBot') isnt -1

    run: (message) ->
      i = message.indexOf('meet')
      name = message.substring(0, i).trim()
      actions.send "Hello #{ name }, I'm SSBot!"

module.exports = { commands: commands, init: init }
