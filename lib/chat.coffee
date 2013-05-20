#!/usr/bin/env coffee

global.xmpp = xmpp = require "node-xmpp"
events       = require 'events'
repl         = require 'repl'
fs           = require 'fs'
global.ltx   = require 'ltx'

EventEmitter = events.EventEmitter
global.XmppService = XmppService = require('./xmpp_service').XmppService
global.XmppClient = XmppClient = require('./client').XmppClient

watchfiles = [ 'chat.coffee', 'client.coffee', 'config.coffee', 'xmpp_service.coffee', 'xmpp_presence.coffee', 'cli_able.coffee' ]

fs.watch '.', (event, path)->
  if (path in watchfiles)and event == 'change'
    console.log event, path, '-> exiting'
    process.exit()

config      = require "./config"

global.client  = client = new XmppClient config.LOCALCLIENT
global.comp  = comp = new XmppService config.COMPONENT
#comp.connect()

#comp.addItem ''


repl.start { prompt: "coffee-chat: ", input: process.stdin, output: process.stdout, useGlobal: yes }
