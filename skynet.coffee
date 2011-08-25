#!/usr/bin/env coffee

sys = require 'sys'
util = require 'util'
xmpp = require 'node-xmpp'
account = require './account'
commands = require './commands'

cl = new xmpp.Client
  jid: account.jabberId + '/bot'
  password: account.password

actions =
  send: (message) ->
    util.log "Sending: " + message
    cl.send(new xmpp.Element('message',
        {
          to: account.roomJid + '/' + account.roomNick,
          type: 'groupchat'
        }
      ).
      c('body').
      t(message)
    )

commands.init({
  actions: actions
})
      
cl.on 'online', ->
  util.log("Skynet Online")

  cl.send(new xmpp.Element('presence', { type: 'available' }).
    c('show').t('chat')
  )

  cl.send(new xmpp.Element('presence', {
      to: account.roomJid + '/' + account.roomNick
    }).
    c('x', { xmlns: 'http://jabber.org/protocol/muc' })
  )

  setInterval( ->
    cl.send(' ')
  30000)

cl.on 'stanza', (stanza) ->
  if stanza.attrs.type is 'error'
    util.log '[error]' + stanza
    return

  # ignore everything that isn't a room message
  if not stanza.is 'message' or not stanza.attrs.type is 'groupchat'
    return

  # ignore messages we sent
  if stanza.attrs.from is account.roomJid + '/' + account.roomNick
    return

  body = stanza.getChild 'body'
  # ignore messages without a body
  if not body
    return

  message = body.getText()

  for c of commands.commands
    c = commands.commands[c]
    if c.match message
      c.run message