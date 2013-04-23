#!/usr/bin/env coffee
EventEmitter = require('events').EventEmitter
xmpp         = require "node-xmpp"
repl         = require "repl"
config       = require "./config"
clc          = require 'cli-color'
url          = require 'url'
fs           = require 'fs'

fs.watch '.', (event, path)-> process.exit() if path == 'chat.coffee' and event == 'change'

class CoffeeChat
  # TODO: feature not implemented response\
  # TODO: service discovery         (XEP-0030, XEP-0128)
  # TODO: ad-hoc commands           (XEP-0050)
  # TODO: Message Delivery Receipts (XEP-0184)
  # TODO: Donate tu Uganda (VIM is Charityware)

  constructor: (@profile) ->
    @events = new EventEmitter()
    @events.on 'message',   @handle_message
    @events.on 'iq',        @handle_iq
    @events.on 'iq.get',    @handle_iq_get
    @events.on 'presence',  @handle_presence

  
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
      else console.log stanza.type, stanza.attrs

  handle_iq_get: (stanza) =>
    if stanza.getChild('ping')?
      console.log 'ping'
      stanza.to = stanza.from
      stanza.from = @profile.jid
      @client.send stanza

    if stanza.getChild('time')?
      console.log "time, #{stanza.from}"
      @send_message(stanza.from, "entity time is not yet implemented")

    if stanza.getChild 'query'?
      xmlns = stanza.getChild('query').attr('xmlns')
      console.log clc.blue xmlns

      switch url.parse(xmlns).hash
        when '#items'
          console.log(clc.yellow "#{stanza.from} requested items")
          result = new  xmpp.Iq {type: 'result', to:stanza.from, id:stanza.id}
          query = result.c('query', {
            xmlns:'http://jabber.org/protocol/disco#items'
            node:'http://jabber.org/protocol/commands'})
          jid = new xmpp.JID @profile.jid
          query.c('item',{
            jid:jid.bare()
            node: 'config'
            name: "Dummy Node :D"})
          console.log clc.green result.toString()

          console.log clc.greenBright @client.send result

        when '#info'
          console.log(clc.yellow "#{stanza.from} requested features")
        else console.log(clc.red "#{stanza.from} something funny")

    
  send_message: (to, message) ->
    stanza = new xmpp.Message({ to: to, type: 'chat' })
    stanza.c('body').t(message)
    @client.send(stanza)
    console.log clc.green stanza.toString()



  handle_message: (stanza) -> console.log "#{clc.magenta.bold(stanza.from)}: #{clc.white.bold(stanza.getChildText('body'))}"

  handle_presence: ->

  connect: () ->
    @client = new xmpp.Client @profile
    @stanzas = []

    @client.on 'online', =>
      @STATUS = 'online'
      console.log "should be online"
      @send_presence('hendrik@hoodie.de')

    @client.on 'stanza', (stanza) =>
      @stanzas.push stanza
      @handle_stanza stanza

    @client.on 'error', (error) ->
      console.warn error

  send_presence: (to)->
    # tell everybody
    if to?
      p = new xmpp.Element('presence', {to: to})
    else
      p = new xmpp.Element('presence')
    @client.send p
    # keep alive
    setInterval (=>
      @client.send new xmpp.Element('presence')
      console.log 'online'
    )
    ,1000 * 120

  xep0050_result: ->

  commands:
    say_hello: (caller) ->
      console.log "#{caller} said hello"

  propagate_commands: ->

global.xmpp = xmpp
global.cc = cc = new CoffeeChat config.client_vector
#cc.connect()

repl.start {
  prompt: "coffee-chat: "
  input: process.stdin
  output: process.stdout
  useGlobal: yes
}
