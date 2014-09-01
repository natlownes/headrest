express            = require 'express'
WhoaDB             = require 'whoadb'
moment             = require 'moment'
headrestMiddleware = require 'headrest-middleware'


headrest = (options={}) ->
  app     = options.app or express()
  apiRoot = options.apiRoot or '/api/'
  dbPath  = options.dbPath or '/tmp/whoadb-headrest.json'
  cookieExpiry = -> moment().utc().add('weeks', 2).toDate()

  allowedHeaders = [
    'Content-Type'
    'Cookie'
    'x-requested-with'
    'Accept'
    'Cache-Control'
    'Authorization'
    'Origin'
    'Referer'
    'Pragma'
    'User-Agent'
  ]

  allowedMethods = [
    'GET'
    'POST'
    'PUT'
    'DELETE'
    'OPTIONS'
  ]

  db = new WhoaDB(dbPath)

  app.configure ->
    app.use express.bodyParser()
    app.use express.cookieParser()
    app.use headrestMiddleware(apiRoot: apiRoot)

  setCorsHeaders = (response) ->
    response.header "Access-Control-Allow-Origin", "*"
    response.header "Access-Control-Allow-Credentials", true
    response.header "Access-Control-Allow-Headers", allowedHeaders.join(', ')
    response.header "Access-Control-Allow-Methods", allowedMethods.join(', ')

  app.options "#{apiRoot}*", (request, response, next) ->
    setCorsHeaders(response)
    response.send(200)

  app.all "#{apiRoot}*", (request, response, next) ->
    setCorsHeaders(response)
    next()

  app.get "#{apiRoot}session*", (request, response) ->
    cookieId = request.cookies.headrest

    record   = db.find('session', cookieId)
    code     = if record? then 200 else 404
    out      = if record? then record else null

    response.json(code, out)

  app.post "#{apiRoot}session*", (request, response) ->
    record    = request.body
    record._collection = "session"

    db.save(record)

    response.cookie('headrest', record.id,
      expires: cookieExpiry()
    )

    response.json(201, record)

  app.delete "#{apiRoot}session*", (request, response) ->
    cookieId = request.cookies.headrest
    record   = db.find('session', cookieId)

    db.destroy(record)

    response.cookie('headrest', '',
      expires: new Date(0)
    )

    response.send(204)

  # end session

  createAction = (request, response, opts={}) ->
    collection = request.headrest.collection()

    record = request.body
    record._collection = collection
    db.save(record)

    response.json(201, record)

  app.get "#{apiRoot}*", (request, response) ->
    collection = request.headrest.collection()
    recordId   = request.headrest.id()

    results = if recordId
      db.find(collection, recordId)
    else
      db.all(collection)

    code = if results? then 200 else 404

    response.json(code, results)

  app.post "#{apiRoot}*", createAction

  app.put "#{apiRoot}*", (request, response) ->
    collection = request.headrest.collection()
    recordId   = request.headrest.id()

    record = db.find(collection, recordId)

    code = if record? then 204 else 404

    if record?
      updates = request.body
      updates.id = record.id
      updates._collection = record._collection
      db.save(updates)

    response.send(code)

  app.delete "#{apiRoot}*", (request, response) ->
    collection = request.headrest.collection()
    recordId   = request.headrest.id()

    record = db.find(collection, recordId)
    code   = if record? then 204 else 404

    if record? then db.destroy(record)

    response.send(code)

  process.on 'SIGINT', ->
    db.persist()
    process.exit()

  return app


module.exports = headrest
