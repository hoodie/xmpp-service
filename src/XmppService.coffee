# TODO: service discovery         (XEP-0030, XEP-0128)
# TODO: ad-hoc commands           (XEP-0050)

class exports.XmppService

  constructor: (@node) ->
    {@profile, @connection} = @node
    @node.events.on 'iq.get', @dispatchIqGet
    @node.events.on 'iq.set', @dispatchIqSet

  dispatchIqSet: (stanza) =>

  dispatchIqGet: (stanza) =>

