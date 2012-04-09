request = require 'request'
cheerio = require 'cheerio'

imageSearch = (query, cb) ->
  uri = 'http://images.google.com/search?tbm=isch&q=' + encodeURIComponent(query);
  request({uri: uri}, (error, response, body) ->
    results = []
    $ = cheerio.load(body)
    $('a').each((i, elem) ->
      e = $(this)
      href = e.attr('href')
      if href.indexOf('/imgres') is 0
        query = href.split('?')[1]
        args = query.split('&amp;')
        for a in args
          if a.indexOf('imgurl=') is 0
            results.push(a.split('=')[1])
    )

    cb(results)
  )

module.exports = {
  imageSearch: imageSearch
}