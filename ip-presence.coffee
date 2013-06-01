#!/usr/bin/env coffee

global.xmpp = xmpp = require "node-xmpp"
events      = require 'events'
request     = require 'request'
repl        = require 'repl'
fs          = require 'fs'

EventEmitter = events.EventEmitter
global.XmppService = XmppService = require('./lib/xmpp_service').XmppService
config      = require "./config"



global.client = client = new XmppService config.CLIENT
client.connect()
#client.presence.keep_alive()

global.ip_presence = ip_presence = ->
  request 'http://ip.hoodie.de/', (error, response, body) ->
    global.client.presence.status = body

setInterval ip_presence, 2000


repl.start { prompt: "xmpp: ", input: process.stdin, output: process.stdout, useGlobal: yes }
