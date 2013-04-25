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
  # TODO: Message Delivery Receipts (XEP-0184)
  # TODO: Donate tu Uganda (VIM is Charityware)
  #
  # default events:
  #   stanza
  #   message
  #   presence
  #   iq
  #   iq.set
  #   iq.get

  xmlns:
    items: 'http://jabber.org/protocol/disco#items'
    info: 'http://jabber.org/protocol/disco#info'

  protocols:
    commands: 'http://jabber.org/protocol/commands'

  implement: (mixin) ->
    for key, value of mixin
      switch typeof
        when 'function' this[key] = value
        when 'object'
          @key = value unless @key?
      if thy


  constructor: (@profile) ->
    @events = new EventEmitter()
    @events.on 'stanza',    @handle_stanza
    @events.on 'message',   @handle_message
    @events.on 'presence',  @handle_presence
    @events.on 'iq',        @handle_iq
    @events.on 'iq.get',    @handle_iq_get
    @events.on 'iq.set',    @handle_iq_set

  connect: () ->
    @client = new xmpp.Client @profile
    @client.on 'online', => @sendPresence()
    @client.on 'stanza', (stanza) => @events.emit 'stanza', stanza
    @client.on 'error', (error) -> console.warn clc.redBright error

  handle_stanza: (stanza) =>
    switch stanza.name
      when "message"  then @events.emit "message", stanza
      when "presence" then @events.emit "presence", stanza
      when "iq"       then @events.emit "iq", stanza
      else console.error "received uncategorized stanza", clc.red stanza.toString()
    console.log clc.blackBright stanza.toString() + "\n"

  handle_iq: (stanza) =>
    switch stanza.type
      when "get" then @events.emit "iq.get", stanza
      when "set" then @events.emit "iq.set", stanza
      else console.log stanza.type, stanza.attrs

  sendPresence: (to = 'hendrik@hoodie.de', set_interval = true)->
    # tell everybody
    if to?
      p = new xmpp.Element('presence', {to: to})
    else
      p = new xmpp.Element('presence')
    @client.send p
    # keep alive
    if set_interval
      setInterval (=>
        @send_presence(to, false)
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
      @client.send iq

    if(query = stanza.getChild('query', @xmlns.info))?
      console.log clc.blue query

  handle_message: (stanza) -> console.log "#{clc.magenta.bold(stanza.from)}: #{clc.white.bold(stanza.getChildText('body'))}"

  handle_presence: ->

  #XEP 0050 Ad Hoc Commands
  adhoc_commands:
    "blub"
  compose_command_list: ->
    jid = @client.jid.bare().toString()
    iq = new xmpp.Iq {type:'result'}
    query = iq.c('query', {xmlns:@xmlns.items, node:@protocols.commands})
    for name, command of @commands
      query.c 'item', {jid:jid, node:name , name: command.title}
    return iq

    



  commands:
    say_hello: new XepAdHocCommand 'Call me back', ((from)=> send_message from, 'what shall I say?')

  propagate_commands: ->

module.exports.XmppNode = XmppNode
