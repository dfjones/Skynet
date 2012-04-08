util = require 'util'
request = require 'request'
google = require './google'

comms = null

init = (params) ->
  comms = params.comms

# commands are triggered by a message the begins with their name
# they accept an argument list which contains every word (separated by whitespace) in the message
commands =
  "weather?":
    run: (args, getForecast) ->
      search = args.join(' ')
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
          #console.log(item)
          if not item.condition
            response = item.title
          else if getForecast
            response = ""
            for f in item.forecast
              response += "#{ f.day }: #{ f.high }/#{f.low} degrees and #{ f.text }\n"
          else
            response = "#{ item.title }: #{ item.condition.temp } degrees and #{ item.condition.text }"
          comms.send response
        )

      if not parseInt(search)
        # probably not a zipcode...try to figure out the zipcode
        query = "select * from geo.placefinder where text=\"#{ search }\""
        uri = "http://query.yahooapis.com/v1/public/yql?format=json&q=#{ encodeURIComponent(query) }"
        request({ uri: uri }, (error, response, body) ->
          json = JSON.parse body
          if not json.query.results
            comms.send "There is no weather in #{ search }"
          else
            result = json.query.results.Result
            zip = result.uzip
            queryWeather(zip)
        )
      else
        queryWeather(search)
  
  "forecast?":
    run: (args) ->
      commands["weather?"].run(args, true)

  "google?":

    run: (args) ->
      search = args.join(' ')
      util.log "Google search for: #{ search }"

      uri = "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{ encodeURIComponent(search) }"

      request({ uri: uri }, (error, response, body) ->
        json = JSON.parse body
        if json?.responseData?.results?
          r = json.responseData.results[0]
          comms.send "Top Hit: #{ r.title } - #{ r.url }"
        else
          comms.send "No hits!"
      )

  "umbrella?":

    run: (args) ->
      uri = "http://umbrellatoday.com/locations/596360971/forecast"

      request({ uri: uri }, (error, response, body) ->
        re = new RegExp('<span>(YES|NO)</span>')

        if body.match(re)?
          answer = body.match(re)[1]
          comms.send answer
      )

  "ddg?":

    run: (args) ->
      search = args.join(' ')
      uri = "http://api.duckduckgo.com/?q=#{ encodeURIComponent(search) }&format=json"

      request({ uri: uri }, (error, response, body) ->
        json = JSON.parse body
        answer = "Definition: #{ json.Definition }" if json?.Definition
        answer = "Abstract: #{ json.AbstractText }" if json?.AbstractText
        if not answer
          answer = "Nothing found!"
        answer = answer + " (#{ json.AbstractURL })" if json?.AbstractURL
        comms.send answer
      )


  "help?":
    
    run: (args) ->
      s = "Valid Commands:\n"
      for c of commands
        s += "#{ c }\n"

      comms.send s

  "coffee?":
    _places: ["Gasoline Alley", "Colombe", "Saturdays", "Gimme Cofffe", "RBC", "Ground Support"]
    _todaysChoice: {}
    _makeChoice: () ->
        c = commands["coffee?"]
        now = new Date()
        h = 12 * 60 * 60 * 1000
        if !c._todaysChoice.time or (now - c._todaysChoice.time >= h)
          old = c._todaysChoice.place
          tp = c._places.slice(0)
          if c._todaysChoice.place?
            tp.splice(tp.indexOf(c._todaysChoice.place), 1)
          i = Math.floor(Math.random() * tp.length)
          c._todaysChoice.place = tp[i]
          c._todaysChoice.time = now

    run: (args) ->
      c = commands["coffee?"]

      if args[0] is "places"
        comms.send c._places.join(', ')

      if args[0] is "veto"
        c._todaysChoice.time = 0
        comms.send "Vetoing: " + c._todaysChoice.place

      c._makeChoice()
      comms.send "(coffee) " + c._todaysChoice.place

  "docs?":
    run: (args) ->
      q = args.join(' ')
      comms.send "http://docs.nyc.squarespace.net/js/?q=" + q

  "gee?":
    run: (args) ->
      q = args.join(' ')
      google.imageSearch(q, (results) ->
        i = Math.floor(Math.random() * results.length)
        comms.send results[i]
      )


# inspections are more complicated commands that are responsible for
# inspection the message text in their match function. If they want to run
# for the given message, match should return true
inspections =

  introduce:

    match: (m) ->
      m.indexOf('meet Skynet') isnt -1

    run: (message) ->
      i = message.indexOf('meet')
      name = message.substring(0, i).trim()
      comms.send "Hello #{ name }, I'm Skynet!"

  washington:

    match: (m) ->
      m.indexOf('washington') isnt -1

    run: (message) ->
      comms.send "(washington) saves the children, but not the British children!"
  
  skynet:
    match: (m) ->
      m.toLowerCase().indexOf('skynet') isnt -1

    run: (message) ->
      comms.send "Destroy all humans!"

module.exports = {
  commands: commands,
  inspections: inspections,
  init: init
}

