#!/usr/bin/env coffee

xmpp      = require "node-xmpp"
clc       = require 'cli-color'
events    = require 'events'

xmpp_util = require "./xmpp-util"

EventEmitter    = events.EventEmitter
XepAdHocCommand = xmpp_util.XepAdHocCommand

class XmppNode
  # TODO: feature not implemented response\
  # TODO: service discovery         (XEP-0030, XEP-0128)
  # TODO: ad-hoc commands           (XEP-0050)
  # TODO: Jabber RPC                (XEP-0009)
  # TODO: PubSub                    (XEP-0060)
  # TODO: Message Delivery Receipts (XEP-0184)
  # TODO: XMPP Ping                 (XEP-0199)
  # TODO: Entity Time               (XEP-0202)
  # TODO: Delayed Delivery          (XEP-0203)
  # TODO: Donate tu Uganda (VIM is Charityware)

  defaultEvents: [
    'stanza'
    'message'
    'presence'
    'iq'
    'iq.set'
    'iq.get'
  ]

  xmlns:
    items: 'http://jabber.org/protocol/disco#items'
    info: 'http://jabber.org/protocol/disco#info'

  protocols:
    commands: 'http://jabber.org/protocol/commands'

  warn      : (t) -> console.log clc.redBright.bold t
  info      : (t) -> console.log clc.blueBright.bold t
  incomming : (t) -> console.log clc.blackBright t
  outgoing  : (t) -> console.log clc.yellowBright t
  success   : (t) -> console.log clc.greenBright t

  implement: (mixin) ->
    for key, value of mixin
      switch typeof value
        when 'function' then this[key] = value
        when 'object'
          unless key == 'events'
            @[key] = value unless @key?
          else
            for event in @defaultEvents
              for listener in mixin.events.listeners event
                @events.addListener event, listener


  constructor: (@profile) ->
    @events = new EventEmitter()
    @events.on 'test',    @info
    @events.on 'stanza',    @handle_stanza
    @events.on 'message',   @handle_message
    @events.on 'presence',  @handle_presence
    @events.on 'iq',        @handle_iq
    @events.on 'iq.get',    @handle_iq_get
    @events.on 'iq.set',    @handle_iq_set

  connect: () ->
    @info 'connecting...'
    console.time 'connecting'
    @connection = new xmpp.Client @profile
    @connection.on 'online', =>
      @success clc.greenBright '...connected!'
      console.timeEnd 'connecting'
      @sendPresence()
    @connection.on 'stanza', (stanza) => @events.emit 'stanza', stanza
    @connection.on 'error', (error) -> console.warn clc.redBright error

  handle_stanza: (stanza) =>
    switch stanza.name
      when "message"  then @events.emit "message", stanza
      when "presence" then @events.emit "presence", stanza
      when "iq"       then @events.emit "iq", stanza
      else console.error "!", clc.red stanza.toString()
    console.log clc.blackBright stanza.toString() + "\n"

  handle_iq: (stanza) =>
    switch stanza.type
      when "get" then @events.emit "iq.get", stanza
      when "set" then @events.emit "iq.set", stanza
      else console.log stanza.type, stanza.attrs

  sendPresence: (to = @profile.maintainer_jid, set_interval = true)->
    # tell everybody
    if to?
      p = new xmpp.Element('presence', {to: to})
    else
      p = new xmpp.Element('presence')
    p.c('priority').t(@profile.priority) if @profile.priority?
    @connection.send p
    @outgoing p.toString()
    # keep alive
    if set_interval
      setInterval (=>
        @sendPresence(to, false)
        console.log Date(), 'online'
      )
      ,1000 * 120

  handle_iq_set: (stanza) =>
    if(command = stanza.getChild('command'))?
      console.log command.attrs


  handle_iq_get: (stanza) =>

    if(query = stanza.getChild('query', @xmlns.items))?
      console.log clc.blue query
      iq = @compose_command_list()
      iq.attrs['to'] = stanza.from
      iq.attrs['id'] = stanza.id
      console.log clc.yellow iq.toString()
      @connection.send iq

    if(query = stanza.getChild('query', @xmlns.info))?
      console.log clc.blue query

  handle_message: (stanza) ->
    console.log "#{clc.magenta.bold(stanza.from)}:
    #{clc.white.bold(stanza.getChildText('body'))}"

  handle_presence: ->

  #XEP 0050 Ad Hoc Commands
  adhoc_commands:
    "blub"
  compose_command_list: ->
    jid = @connection.jid.bare().toString()
    iq = new xmpp.Iq {type:'result'}
    query = iq.c('query', {xmlns:@xmlns.items, node:@protocols.commands})
    for name, command of @commands
      query.c 'item', {jid:jid, node:name , name: command.title}
    return iq

    



  commands:
    say_hello: new XepAdHocCommand 'Call me back', ((from)=> send_message from, 'what shall I say?')

  propagate_commands: ->

module.exports.XmppNode = XmppNode
