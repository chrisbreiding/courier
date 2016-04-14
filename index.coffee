express = require 'express'
request = require 'request'
_ = require 'lodash'
config = require './config'

mailgunUrl = "https://api.mailgun.net/v3/#{config.MAIL_DOMAIN}/messages"

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

normalizeReferrer = (req, res, next)->
  req.referrer = req.get('Referrer') || req.get 'Origin'
  next()

app.use normalizeContent
app.use normalizeReferrer
app.use express.json()
app.use express.urlencoded()

app.post '/', (req, res)->
  res.setHeader 'Access-Control-Allow-Origin', '*'

  recipient = _.find config.RECIPIENTS, (recipient)->
    recipient.regex.test req.referrer

  return res.send 403 unless recipient

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

  onSuccess = (result)->
    res.send 200, result

  onError = (error)->
    res.send 500, error

  request.post mailgunUrl, data, (err, response, body)->
    if err
      onError err
    else
      onSuccess body

app.listen config.PORT, ->
  console.log "listening on #{config.PORT}..."
