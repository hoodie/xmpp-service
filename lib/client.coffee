ltx   = require 'ltx'
XmppService = require('./xmpp_service').XmppService

# TODO: Jabber RPC                 (XEP-0009)
# TODO: XEP-0146: Remote Controlling Clients
# TODO: XEP-0122: Data Forms Validation

class exports.XmppClient extends XmppService
  constructor: (@config) ->
    super @config

    change_status_form = {
      instructions: 'Choose the status and status message'
      fields:[

        {type: 'hidden', var: 'FORM_TYPE', value:'http://jabber.org/protocol/rc'}
        {label:'Status', type: 'list-single', var: 'status', options: @presence.SHOW
        }
      ]
    }

    @addCommand('Change Status', change_status_form)


  addCommand: (name, form_structure)->
    @createDataForm('Change Status', form_structure)

  createDataForm: (name, structure) ->
    #    <x xmlns='jabber:x:data' type='form'>

    form = new ltx.Element 'x', {xmlns: 'jabber:x:data', type:'form'}
    form.c('title').t(name)
    for field_content in structure.fields

      value = field_content.value
      field_content.value = undefined
      options = field_content.options
      field_content.options = undefined

      field = form.c('field', field_content)
      if value?
        field.c('value').t(value)

      for label, value of options
        option = field.c('option',{label: label})
        option.c('value').t value



    console.log form.toString()
    

  takeForm: (form_xml) ->


