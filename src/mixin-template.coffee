EventEmitter = require('events').EventEmitter

mixin_template = {

  events: new EventEmitter()

}

util.events.addListener 'message', (stanza) ->

exports.mixin_template = mixin_template
