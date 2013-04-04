#!/usr/bin/env coffee
xmpp = require "node-xmpp"
EventEmitter = require('events').EventEmitter
repl = require "repl"
config = require "./config"


class CoffeeChat

  constructor: (@profile) ->
    @events = new EventEmitter()
    @events.on 'message',   @handle_message
    @events.on 'iq',        @handle_iq
    @events.on 'presence',  @handle_presence

    @connect()

  

  handle_iq: (stanza) ->
    console.log stanza.attrs
  handle_message: (stanza) ->
    console.log "YOU RECEIVED A MESSAGE"
    console.log stanza.children.body
  handle_presence: ->

  connect: () ->
    @client = new xmpp.Client @profile
    @stanzas = []

    @client.on 'online', =>
      @STATUS = 'online'
      console.log "should be online"
      @send_presence()

    @client.on 'stanza', (stanza) =>
      @stanzas.push stanza

      switch stanza.name
        when "message"  then @events.emit "message", stanza
        when "presence" then @events.emit "presence", stanza
        when "iq"       then @events.emit "iq", stanza
        else console.error "received uncategorized stanza", stanza

    @client.on 'error', (error) ->
      console.warn error

  send_presence: ->
    # tell everybody
    @client.send new xmpp.Element('presence')
    # keep alive
    setInterval (=>
      @client.send new xmpp.Element('presence')
      console.log 'online'
    )
    ,1000 * 120

  commands:
    say_hello: (caller) ->
      console.log "#{caller} said hello"

  propagate_commands: ->



  send: (receiver, message) ->

global.cc = new CoffeeChat config.client_vector


repl.start {
  prompt: "coffee-chat: "
  input: process.stdin
  output: process.stdout
  useGlobal: yes
}
