#!/usr/bin/env coffee

xmpp      = require "node-xmpp"
clc       = require 'cli-color'
events    = require 'events'

xmpp_util = require "./xmpp-util"

EventEmitter    = events.EventEmitter
XepAdHocCommand = xmpp_util.XepAdHocCommand

class XmppNode
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
  name: 'node'

  xmlns:
    items: 'http://jabber.org/protocol/disco#items'
    info:  'http://jabber.org/protocol/disco#info'

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
          unless key == 'listeners'
            @[key] = value unless @key?
            @info key
          else
            for event, listeners of value
              for name, listener of listeners
                `__bind(listener, this)`
                @info "#{name} for #{event}"
                @events.addListener event, listener


  constructor: (@profile) ->
    @events = new EventEmitter()
    @events.on 'test',    @info
    @events.on 'stanza',    @handleStanza
    @events.on 'message',   @handleMessage
    @events.on 'presence',  @handlePresence
    @events.on 'iq',        @handleIq
    @events.on 'iq.get',    @handleIqGet
    @events.on 'iq.set',    @handleIqSet
    @events.on 'newListener', (func) -> func.parent = this

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

  handleStanza: (stanza) =>
    switch stanza.name
      when "message"  then @events.emit "message", stanza
      when "presence" then @events.emit "presence", stanza
      when "iq"       then @events.emit "iq", stanza
      else console.error "!", clc.red stanza.toString()
    console.log clc.blackBright stanza.toString() + "\n"

  handleIq: (stanza) =>
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

  handleIqSet: (stanza) =>
    if(command = stanza.getChild('command'))?
      console.log command.attrs

  handleIqGet: (stanza) =>
    @incomming query if(query = stanza.getChild('query', @xmlns.items))?
    @incomming query if(query = stanza.getChild('query', @xmlns.info))?

  handleMessage: (stanza) ->
    console.log "#{clc.magenta.bold(stanza.from)}:
    #{clc.white.bold(stanza.getChildText('body'))}"

  handlePresence: ->

module.exports.XmppNode = XmppNode
