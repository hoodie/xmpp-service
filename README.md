# node-xmpp-node

A platform to implement [XEPs](http://xmpp.org/xmpp-protocols/xmpp-extensions/) using [node-xmpp](https://github.com/astro/node-xmpp)

## API and Design

Wait for it! I have no clue yet.

At the moment the architecture allows for mixins that implement their own event listeners, see src/mixin-template.coffee
The most basic events at the moment are:
* stanza
* message
* presence
* iq
  * get
  * set

More to come soonish.

## Objectives

* At one point allow arbitraty node.js applications to offer interfaces through xmpp service discovery.
* 

## Planned XEPs
- [ ] service discovery         (XEP-0030, XEP-0128)
- [ ] ad-hoc commands           (XEP-0050)
- [ ] Jabber RPC                (XEP-0009)
- [ ] PubSub                    (XEP-0060)
- [ ] Message Delivery Receipts (XEP-0184)
- [ ] XMPP Ping                 (XEP-0199)
- [ ] Entity Time               (XEP-0202)
