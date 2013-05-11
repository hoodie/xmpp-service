xmpp      = require "node-xmpp"
events    = require 'events'
clc        = require 'cli-color'

EventEmitter = events.EventEmitter
CliAble      = require('./CliAble').CliAble
XmppPresence = require('./XmppPresence').XmppPresence

# TODO: Jabber RPC                (XEP-0009)
# TODO: PubSub                    (XEP-0060)
# TODO: Entity Capabilities       (XEP-0115)
# TODO: Delayed Delivery          (XEP-0203)
# TODO: Donate tu Uganda (VIM is Charityware)
# TODO: Message Delivery Receipts (XEP-0184)
#
# TODO: rethink:
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
   #'urn:xmpp:version'                       # (XEP-0092) Software Version # NOT IMPLEMENTED
  ]

  TYPES:
    CLIENT: 'client'
    COMPONENT: 'component'

  PROTOCOLS:
    COMMANDS: 'http://jabber.org/protocol/commands'

  constructor: (@config) ->
    @success "XmppNode"
    {@host, @jid, @type} = @config
    @jid = new xmpp.JID @jid

    @events = new EventEmitter()

    @events.on 'stanza',    @stanzaPrint
    #@events.on 'message',   @dispatchMessage
    #@events.on 'presence',  @dispatchPresence
    #@events.on 'iq',        @dispatchIq
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
    @presence = new XmppPresence this

    @connection.on 'online', =>
      @success '...connected!'
      console.timeEnd 'connecting'
      @presence.send() if @TYPES[@type] == 'client'

    @connection.on 'stanza', (stanza) =>
      @dispatchStanza stanza

    @connection.on 'error', (error) ->
      throw error
    return

  send: (stanza) -> @connection.send stanza

  sendMessage: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'chat' })
    stanza.c('body').t(message)
    @connection.send(stanza)
    console.log clc.green stanza.toString()


  ###
  # Dispatchers
  ###
  dispatchStanza: (stanza) ->
    @events.emit 'stanza', stanza
    switch stanza.name
      when 'message'  then @dispatchMessage stanza
      when 'presence' then @dispatchPresence stanza
      when 'iq'       then @dispatchIq stanza
      else @error "!", stanza.toString()
  dispatchPresence: (stanza) ->
    @events.emit 'presence', stanza

  dispatchIq: (stanza) ->
    @events.emit 'iq', stanza
    switch stanza.type
      when 'get' then @dispatchIqGet stanza
      when 'set' then @dispatchIqSet stanza
      else console.log stanza.type, stanza.attrs

  dispatchIqSet: (stanza) ->

  dispatchIqGet: (stanza) ->
    @handleTime stanza if stanza.getChild('time')?  # (XEP-0202) Entity Time
    @handlePing stanza if stanza.getChild('ping')?  # (XEP-0199) XMPP Ping

  dispatchMessage: (stanza) ->
    @handleMessage stanza







  ###
  # Handlers
  ###
  handleMessage: (message) =>
    console.log "#{clc.magenta.bold(message.from)}:
    #{clc.white.bold(message.getChildText('body'))}"

  stanzaPrint: (stanza) =>
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

