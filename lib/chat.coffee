#!/usr/bin/env coffee

global.xmpp = xmpp = require "node-xmpp"
events       = require 'events'
repl         = require 'repl'
fs           = require 'fs'
EventEmitter = events.EventEmitter
global.XmppService = XmppService = require('./XmppService').XmppService

watchfiles = [ 'chat.coffee', 'config.coffee', 'XmppService.coffee', 'XmppPresence.coffee' ]

fs.watch '.', (event, path)->
  if (path in watchfiles)and event == 'change'
    console.log event, path, '-> exiting'
    process.exit()

config      = require "./config"

global.xn  = xn = new XmppService config.LOCALCLIENT
global.xc  = xc = new XmppService config.COMPONENT
xn.connect()
xc.connect()
#xn.presence.keep_alive()
#xs.composeFeatures()

repl.start { prompt: "coffee-chat: ", input: process.stdin, output: process.stdout, useGlobal: yes }
