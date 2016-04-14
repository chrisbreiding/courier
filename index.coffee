express = require 'express'
Mailgun = require 'mailgun-js'
config = require './config'

mailgun = new Mailgun apiKey: config.API_KEY, domain: config.MAIL_DOMAIN
app = express()

normalizeContent = (req, res, next)->
  if req.get 'Content-Type'
    next()
  else
    text = ''
    req.setEncoding 'utf8'
    req.on 'data', (chunk)-> text += chunk
    req.on 'end', ->
      req.body = {}
      for pair in text.split '&'
        pieces = pair.split '='
        req.body[pieces[0]] = pieces[1]
      next()

app.use normalizeContent
app.use express.json()
app.use express.urlencoded()

app.post '/', (req, res)->
  recipient = config.RECIPIENTS.filter((recipient)->
    (req.get('Origin') or '').indexOf(recipient.domain) > -1
  )[0]

  if recipient
    res.setHeader 'Access-Control-Allow-Origin', recipient.domain
  else
    return res.send 403

  name    = req.body.name
  email   = req.body.email
  message = req.body.message

  data =
    from: recipient.email
    to: recipient.email
    subject: "Message sent through #{recipient.domain}"
    html: """
      <h3>Name</h3>
      <p>#{name}</p>
      <h3>Email</h3>
      <p>#{email}</p>
      <h3>Message</h3>
      <p>#{message}</p>
    """
    text: """
      Name: #{name},
      Email #{email},
      Message: #{message}
    """

  onSuccess = ->
    res.send 200, {}

  onError = (error)->
    res.send 500, error

  mailgun.messages().send data, (err, body)->
    if err
      onError err
    else
      onSuccess()

app.listen config.PORT, ->
  console.log "listening on #{config.PORT}..."
