#!/usr/bin/env coffee

global.xmpp = xmpp = require "node-xmpp"
events       = require 'events'
repl         = require 'repl'
fs           = require 'fs'
EventEmitter = events.EventEmitter
global.XmppNode    = XmppNode    = require('./XmppNode').XmppNode
global.XmppService = XmppService = require('./XmppService').XmppService

watchfiles = [ 'start.coffee', 'config.coffee', 'XmppNode.coffee', 'XmppBasics.coffee', 'XmppService.coffee', 'XmppPresence.coffee' ]

fs.watch '.', (event, path)->
  if (path in watchfiles)and event == 'change'
    console.log event, path, '-> exiting'
    process.exit()


config      = require "./config"

global.xn  = xn = new XmppService config
global.subclient  = subclient = new XmppService subclientconfig
xn.connect()
#xs.composeFeatures()

repl.start { prompt: "coffee-chat: ", input: process.stdin, output: process.stdout, useGlobal: yes }
