#!/usr/bin/env coffee

sys = require 'util'
util = require 'util'
xmpp = require 'node-xmpp'
account = require './account'
commands = require('./commands')

parseCommand = (message) ->
  parts = message.split(' ')
  return {
    command: parts[0]?.trim()
    args: parts[1..]
  }

processMessage = (message) ->
  mParts = parseCommand(message)

  # if a command exists, run it
  commands.commands[mParts.command]?.run(mParts.args)

  # run all inspections on message body
  for i of commands.inspections
    i = commands.inspections[i]
    if i.match message
      try
        i.run message
      catch error
        util.log "Error: #{ error }"

comms =
  room: null,
  setRoom: (roomId) ->
    comms.room = roomId + '/' + account.roomNick
  sender: null,
  send: (message) ->
    util.log "Sending: " + message
    if comms.sender?
      util.log "Sending reply to: " + comms.sender
      to = comms.sender
      type = 'chat'
    else
      to = comms.room
      type = 'groupchat'

    cl.send(new xmpp.Element('message',
        {
          to: to,
          type: type
        }
      ).
      c('body').
      t(message)
    )

commands.init({
  comms: comms
})

cl = new xmpp.Client
  jid: account.jabberId + '/bot'
  password: account.password
      
cl.on 'online', ->
  util.log("Skynet Online")

  cl.send(new xmpp.Element('presence', { type: 'available' }).
    c('show').t('chat')
  )

  for room in account.roomJids
    util.log("Connecting to " + room)
    do (room) ->
      announcePresence = ->
        cl.send(new xmpp.Element('presence', {
            to: room + '/' + account.roomNick
          }).
          c('x', { xmlns: 'http://jabber.org/protocol/muc' })
        )
      announcePresence()
      setInterval(announcePresence, 30000)

cl.on 'stanza', (stanza) ->
  if stanza.attrs?.type is 'error'
    util.log '[error]' + stanza
    return

  # ignore everything that isn't a room message
  if not stanza.is('message')
    return

  if stanza.attrs?.type is 'chat'
    comms.sender = stanza.attrs.from
  else if stanza.attrs?.type is 'groupchat'
    comms.sender = null
  else
    return

  # ignore messages we sent
  if stanza.attrs.from is account.roomJid + '/' + account.roomNick
    return

  comms.setRoom(stanza.attrs.from.split('/')[0])

  body = stanza.getChild 'body'
  # ignore messages without a body
  if not body
    return

  message = body.getText()

  processMessage message


exports.processMessage = processMessage
