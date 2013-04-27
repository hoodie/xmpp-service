events    = require 'events'
EventEmitter    = events.EventEmitter

util = {

  STATUSES:
    AVAILABLE : 'available'
    CHAT      : 'chat'
    AWAY      : 'away'
    DND       : 'dnd'
    XA        : 'xa'
    ONLINE    : 'online'
    OFFLINE   : 'offline'

  listeners: 'foo'

  events: new EventEmitter()


  sendMessage: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'chat' })
    stanza.c('body').t(message)
    @connection.send(stanza)
    console.log clc.green stanza.toString()

  dummyTest: -> @events.emit 'test', 'dummyTest'

  probe: (buddy) ->
    presence = new xmpp.Element('presence', {type: 'probe', to: buddy})
    @connection.send presence

  setStatusMessage: (message, to = null) ->
    help = -> console.log "setStatusMessage()"
    @setStatus '', message, to

  setStatus: (show, message, to = null) ->
    status = @STATUSES[show.toUpperCase()]

    presence = if to? then new xmpp.Presence {to: to} else new xmpp.Presence()

    presence.c("status").t(message) if message?
    if show? and status?
      presence.c("show").t(status)
    @connection.send presence

  composeCommandList: ->
    jid = @connection.jid.bare().toString()
    iq = new xmpp.Iq {type:'result'}
    query = iq.c('query', {xmlns:@xmlns.items, node:@protocols.commands})
    for name, command of @commands
      query.c 'item', {jid:jid, node:name , name: command.title}
    return iq

}

util.events.addListener 'message', (stanza) ->
  console.log stanza.getChild('body').getText().length


class XepAdHocCommand
  constructor: (@title, @function) ->

exports.XepAdHocCommand = XepAdHocCommand
exports.xmpp_util = util
