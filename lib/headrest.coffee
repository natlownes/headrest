express        = require 'express'
WhoaDB         = require 'whoadb'
headrestMiddleware = require 'headrest-middleware'


headrest = (options={}) ->
  app     = options.app or express()
  apiRoot = options.apiRoot or '/api/'
  dbPath  = options.dbPath or '/tmp/whoadb-headrest.json'

  db = new WhoaDB(dbPath)

  app.configure ->
    app.use express.bodyParser()
    app.use express.cookieParser()
    app.use headrestMiddleware(apiRoot: apiRoot)

  setCorsHeaders = (response) ->
    response.header("Access-Control-Allow-Origin", "*")
    response.header("Access-Control-Allow-Credentials", true)
    response.header( "Access-Control-Allow-Headers",
      "Content-Type, Cookie, x-requested-with, Accept, Cache-Control, Authorization, Origin, Referer, Pragma, User-Agent"
    )
    response.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")

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
    out      = if record?
      JSON.stringify(record)
    else
      null

    response.json(code, out)

  app.post "#{apiRoot}session*", (request, response) ->
    cookieId  = request.cookies.headrest
    if cookieId then db.destroy(db.find('session', cookieId))
    
    record    = request.body
    record._collection = "session"

    db.save(record)

    response.cookie('headrest', record.id,
      expires: (new Date(Date.now() + ((3600 * 1000) * 24)))
    )

    response.json(201, JSON.stringify(record))

  app.delete "#{apiRoot}session*", (request, response) ->
    cookieId = request.cookies.headrest
    record   = db.find('session', cookieId)

    db.destroy(record)

    response.cookie('headrest', '',
      expires: new Date(0)
    )

    response.send(204)

  # end session

  indexAction = (request, response, opts={}) ->
    collection = request.headrest.collection()

    records = db.all(collection)

    response.json(200, JSON.stringify(records))

  createAction = (request, response, opts={}) ->
    collection = request.headrest.collection()

    record = request.body
    record._collection = collection
    db.save(record)

    response.json(201, JSON.stringify(record))

  app.get "#{apiRoot}*", (request, response) ->
    collection = request.headrest.collection()
    recordId   = request.headrest.id()

    results = if recordId
      db.find(collection, recordId)
    else
      db.all(collection)

    code   = if (results?) then 200 else 404
    out    = JSON.stringify(results)

    response.json(code, out)

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
