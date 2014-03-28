express = require 'express'
mandrill = require 'mandrill-api/mandrill'
_ = require 'lodash'
config = require './config'

app = express()
mandrillClient = new mandrill.Mandrill config.API_KEY

app.use express.json()
app.use express.urlencoded()

app.post '/', (req, res)->
  res.setHeader 'Access-Control-Allow-Origin', '*'

  # use Origin for IEs < 10, which don't send referrer with XDomainRequest
  referrer = req.get('Referrer') || req.get 'Origin'
  recipient = _.find config.RECIPIENTS, (recipient)->
    recipient.regex.test referrer

  return res.send 403 unless recipient

  name    = req.body.name
  email   = req.body.email
  message = req.body.message

  data =
    template_name: 'website-contact-form'
    template_content: [
      { name: 'contact-name',    content: name    }
      { name: 'contact-email',   content: email   }
      { name: 'contact-message', content: message }
    ]
    message:
      from_name: name
      from_email: recipient.email
      to: [ email: recipient.email ]

  onSuccess = (result)->
    res.send 200, result

  onError = (error)->
    res.send 500, error

  mandrillClient.messages.sendTemplate data, onSuccess, onError

app.listen config.PORT, ->
  console.log "listening on #{config.PORT}..."
