xmpp      = require "node-xmpp"
events    = require 'events'
clc        = require 'cli-color'

EventEmitter = events.EventEmitter
CliAble      = require('./CliAble').CliAble
XmppPresence = require('./XmppPresence').XmppPresence

# TODO: Jabber RPC                (XEP-0009)
# TODO: PubSub                    (XEP-0060)
# TODO: Delayed Delivery          (XEP-0203)
# TODO: Donate tu Uganda (VIM is Charityware)
# TODO: Message Delivery Receipts (XEP-0184)
#
# rethink:
#   stanza -> dispatchStanza
#     -> <presence>
#     -> <message>
#     -> <iq>
#       -> dispatchQuery for <query> in <iq>



## basically routes stanza events to different dispatchrs
class module.exports.XmppNode extends CliAble

  defaultEvents: ['stanza', 'message', 'presence', 'iq', 'iq.set', 'iq.get']

  XMLNS:
    ITEMS: 'http://jabber.org/protocol/disco#items'
    INFO:  'http://jabber.org/protocol/disco#info'
    PING:  'urn:xmpp:ping'
    TIME:  'urn:xmpp:time'


  #TODO: propagate features
  FEATURES: [
    'http://jabber.org/protocol/disco#info'  # (XEP-0030 Service Discovery)
    'http://jabber.org/protocol/disco#items' # (XEP-0030 Service Discovery)
    'urn:xmpp:ping'                          # (XEP-0199) XMPP Ping
    'urn:xmpp:receipts'                      # (XEP-0199) XMPP Ping
    'urn:xmpp:time'                          # (XEP-0202) Entity Time
    #'urn:xmpp:version'                       # (XEP-0092) Software Version
  ]

  TYPES:
    CLIENT: 'client'
    COMPONENT: 'component'

  PROTOCOLS:
    COMMANDS: 'http://jabber.org/protocol/commands'

  STATUSES:
    AVAILABLE : 'available'
    CHAT      : 'chat'
    AWAY      : 'away'
    DND       : 'dnd'
    XA        : 'xa'
    ONLINE    : 'online'
    OFFLINE   : 'offline'

  constructor: (@config) ->
    @success "XmppNode"
    {@host, @jid, @type} = @config
    @jid = new xmpp.JID @jid

    @events = new EventEmitter()

    @events.on 'stanza',    @dispatchStanza
    @events.on 'message',   @dispatchMessage
    #@events.on 'presence',  @dispatchPresence
    @events.on 'iq',        @dispatchIq
    #@events.on 'iq.get',    @dispatchIqGet
    #@events.on 'iq.set',    @dispatchIqSet

  connect: () ->
    @info 'connecting...'
    console.time 'connecting'
    switch @TYPES[@type]
      when 'client' then @connection = new xmpp.Client @config
      when 'component' then @connection = new xmpp.Component @config
      else
        @connection = undefined
        throw new Error "Undefined type off connection - Check config.coffee"
    @presence = new XmppPresence @config, @connection

    @connection.on 'online', =>
      @success '...connected!'
      console.timeEnd 'connecting'
      @presence.send() if @TYPES[@type] == 'client'

    @connection.on 'stanza', (stanza) =>
      @events.emit 'stanza', stanza

    @connection.on 'error', (error) ->
      throw error
    return

  dispatchStanza: (stanza) =>
    switch stanza.name
      when 'message'  then @events.emit 'message', stanza
      when 'presence' then @events.emit 'presence', stanza
      when 'iq'       then @events.emit 'iq', stanza
      else @error "!", stanza.toString()

  dispatchIq: (stanza) =>
    switch stanza.type
      when 'get' then @events.emit 'iq.get', stanza
      when 'set' then @events.emit 'iq.set', stanza
      else console.log stanza.type, stanza.attrs

  dispatchMessage: (stanza) ->
    console.log "#{clc.magenta.bold(stanza.from)}:
    #{clc.white.bold(stanza.getChildText('body'))}"

  dispatchIqSet: (stanza) =>

  dispatchIqGet: (stanza) =>
    @handleTime stanza if stanza.getChild('time')?  # (XEP-0202) Entity Time
    @handlePing stanza if stanza.getChild('ping')?  # (XEP-0199) XMPP Ping

  handleStanza: (stanza) ->
    unless stanza.type == 'error'
      @incomming stanza.toString()
    else
      @error stanza.toString()

  # (XEP-0202) Entity Time
  handleTime: (stanza = new xmpp.Iq({type:'get', from: 'dummy', id:'fake'})) ->
    date = new Date()
    iq = new xmpp.Iq {type: 'result', from: @jid, to: stanza.from, id: stanza.id}
    iq.c('time', {xmlns: @XMLNS.TIME})
      .c('tzo').t(date.getTimezoneOffset()).up()
      .c('utc').t(date.toISOString())
    @connection.send iq
    @outgoing iq.toString()



  # (XEP-0199) XMPP Ping
  handlePing: (stanza) ->
    iq = new xmpp.Iq {type: 'result', from: @jid, to: stanza.from, id: stanza.id}
    @connection.send iq
    @outgoing iq.toString()

  send: (stanza) -> @connection.send stanza

  sendMessage: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'chat' })
    stanza.c('body').t(message)
    @connection.send(stanza)
    console.log clc.green stanza.toString()
