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


## basically routes stanza events to different dispatchrs
class module.exports.XmppNode extends CliAble

  defaultEvents: ['stanza', 'message', 'presence', 'iq', 'iq.set', 'iq.get']

  XMLNS:
    ITEMS: 'http://jabber.org/protocol/disco#items'
    INFO:  'http://jabber.org/protocol/disco#info'
    TIME:  'urn:xmpp:time'


  #TODO: propagate features
  FEATURES: [
    'urn:xmpp:time' # (XEP-0202) Entity Time
  ]

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

  constructor: (@profile) ->
    @success "XmppNode"

    @events = new EventEmitter()
    @events.on 'stanza',    @dispatchStanza
    @events.on 'message',   @dispatchMessage
    #@events.on 'presence',  @dispatchPresence
    @events.on 'iq',        @dispatchIq
    @events.on 'iq.get',    @dispatchIqGet
    @events.on 'iq.set',    @dispatchIqSet

  connect: () ->
    @info 'connecting...'
    console.time 'connecting'
    @connection = new xmpp.Client @profile
    @presence = new XmppPresence @profile, @connection
    @connection.on 'online', =>
      @success '...connected!'
      console.timeEnd 'connecting'
      @presence.send()

    @connection.on 'stanza', (stanza) =>
      @events.emit 'stanza', stanza

    @connection.on 'error', (error) -> @error error
    return

  dispatchStanza: (stanza) =>
    switch stanza.name
      when 'message'  then @events.emit 'message', stanza
      when 'presence' then @events.emit 'presence', stanza
      when 'iq'       then @events.emit 'iq', stanza
      else @error "!", stanza.toString()
    @incomming stanza.toString() + "\n"

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
    @incomming query if(query = stanza.getChild('query', @XMLNS.ITEMS))?
    @incomming query if(query = stanza.getChild('query', @XMLNS.INFO))?

    @handleTime stanza if stanza.getChild('time')?  # (XEP-0202) Entity Time
    @handlePing stanza if stanza.getChild('ping')?  # (XEP-0199) XMPP Ping

  # (XEP-0202) Entity Time
  handleTime: (stanza = new xmpp.Iq({type:'get', from: 'dummy', id:'fake'})) =>
    date = new Date()
    iq = new xmpp.Iq {type: 'result', from: @profile.jid, to: stanza.from, id: stanza.id}
    iq.c('time', {xmlns: @XMLNS.TIME})
      .c('tzo').t(date.getTimezoneOffset())
      .c('o').t(date.toISOString())
    @connection.send iq
    @outgoing iq.toString()



  # TODO: (XEP-0199) XMPP Ping
  handlePing: (stanza) =>
    console.log this
    console.log typeof this
    console.log this.name
    console.log @profile
    #console.log 'ping'
    #stanza.to = stanza.from
    #stanza.from = @profile.jid
    #@client.send stanza

  sendMessage: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'chat' })
    stanza.c('body').t(message)
    @connection.send(stanza)
    console.log clc.green stanza.toString()
