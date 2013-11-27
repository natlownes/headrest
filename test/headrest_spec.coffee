Q        = require('q')
expect   = require('chai').expect
request  = require('superagent')
WhoaDB   = require('whoadb')
helpers  = require('./helpers')
headrest = require('../src/index')
fs       = require('fs')
moment   = require('moment')


dbPath = '/tmp/headrest-test.json'

app      = headrest(
  apiRoot: '/headrest/'
  dbPath:  dbPath
)

app.listen(19134)

urlBase = "http://localhost:19134"

urlFor = (path) ->
  "#{urlBase}#{path}"

dbCleanup = (path) ->
  if fs.existsSync(path) then fs.unlinkSync(path)

before ->
  dbCleanup(dbPath)

after ->
  dbCleanup(dbPath)

beforeEach ->
  @db = new WhoaDB(dbPath)
  @db.drop()

describe 'OPTIONS request', ->
  beforeEach ->
    @request = request.agent()

  it 'should return 200', (done) ->
    req = helpers.request(
      @request,
      'options',
      (urlFor '/headrest/honk'),
    )

    req.done (res) ->
      expect(res.status).to.equal 200
      done()

  it 'should set Access-Control-Allow-Origin wildcard', (done) ->
    req = helpers.request(
      @request,
      'options',
      (urlFor '/headrest/honk'),
    )

    req.done (res) ->
      expect( res.headers['access-control-allow-origin'] ).to.equal '*'
      done()

  it 'should set Access-Control-Allow-Credentials to true', (done) ->
    req = helpers.request(
      @request,
      'options',
      (urlFor '/headrest/honk'),
    )

    req.done (res) ->
      expect( res.headers['access-control-allow-credentials'] ).
        to.equal 'true'
      done()

  it 'should allow headers', (done) ->
    req = helpers.request(
      @request,
      'options',
      (urlFor '/headrest/honk'),
    )

    req.done (res) ->
      expect( res.headers['access-control-allow-headers'] ).
        to.equal 'Content-Type, Cookie, x-requested-with, Accept, Cache-Control, Authorization, Origin, Referer, Pragma, User-Agent'
      done()

  it 'should allow http methods', (done) ->
    req = helpers.request(
      @request,
      'options',
      (urlFor '/headrest/honk'),
    )

    req.done (res) ->
      expect( res.headers['access-control-allow-methods'] ).
        to.equal 'GET, POST, PUT, DELETE, OPTIONS'
      done()

describe 'session resource', ->

  describe 'POST', ->

    it 'should respond with HTTP 201', (done) ->
      req = helpers.request(
        @request,
        'post',
        (urlFor '/headrest/session'),
        (username: 'Billy Martin', password: 'brawlin')
      )

      req.done (res) ->
        expect( res.status ).to.equal 201
        done()

    it 'should set a cookie with name of "headrest"', (done) ->
      req = helpers.request(
        @request,
        'post',
        (urlFor '/headrest/session'),
        (username: 'Billy Martin', password: 'brawlin')
      )

      req.done (res) ->
        expect( res.headers['set-cookie'] ).
          to.match /^headrest=\w+/
        done()

    it 'should set expires date on cookie to 2 weeks from now', (done) ->
      expectedExpiryDay = moment().utc().add('weeks', 2).format('ddd, DD MMM YYYY')

      req = helpers.request(
        @request,
        'post',
        (urlFor '/headrest/session'),
        (username: 'Billy Martin', password: 'brawlin')
      )

      req.done (res) ->
        expect( res.headers['set-cookie'][0] ).
          to.have.string "Expires=#{expectedExpiryDay}"
        done()

    it 'should respond with a session record', (done) ->
        req = helpers.request(
          @request,
          'post',
          (urlFor '/headrest/session'),
          (username: 'Billy Martin', password: 'brawlin')
        )

        req.done (res) ->
          record = JSON.parse(res.body)
          expect(record.id).not.to.be.undefined
          expect(record.username).to.equal 'Billy Martin'
          expect(record._collection).to.equal 'session'
          done()

  describe 'GET', ->

    context 'when not previously done POST', ->
      beforeEach ->
        @request = request.agent()

      it 'should be 404', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/session')
        )

        req.done (res) ->
          expect( res.status ).to.equal 404
          done()

    context 'when done POST and been assigned cookie', ->
      beforeEach (done) ->
        @request = request.agent()
        login = helpers.loginUser(@request, urlFor '/headrest/session')

        login.done (resp) -> done()

      it 'should be 200', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/session')
        )

        req.done (res) ->
          expect( res.status ).to.equal 200
          done()

      it 'should return a session object', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/session')
        )

        req.done (res) ->
          obj = JSON.parse(res.body)

          expect( obj.username ).to.equal 'Billy Martin'
          expect( obj.id ).not.to.be.undefined
          done()

  describe 'DELETE', ->

    context 'when done POST and been assigned cookie', ->
      beforeEach (done) ->
        @request = request.agent()
        login = helpers.loginUser(@request, urlFor '/headrest/session')

        login.done (resp) -> done()

      it 'should return 204 on DELETE', (done) ->
        deletion = helpers.deleteSession(@request, urlFor '/headrest/session')

        deletion.done (res) ->
          expect( res.status ).to.equal 204
          done()
        deletion.fail -> new Error('session still exists')

      it 'should set cookie value to empty string', (done) ->
        deletion = helpers.deleteSession(@request, urlFor '/headrest/session')

        deletion.done (res) ->
          expect( res.headers['set-cookie'][0] ).to.have.string 'headrest=;'
          done()
        deletion.fail -> new Error('session cookie value')

      it 'should set expiry to unix epoch', (done) ->
        deletion = helpers.deleteSession(@request, urlFor '/headrest/session')
        expectedExpiry = 'Expires=Thu, 01 Jan 1970 00:00:00 GMT'

        deletion.done (res) ->
          expect( res.headers['set-cookie'][0] ).
            to.have.string expectedExpiry
          done()
        deletion.fail -> new Error('session cookie value')

      context 'after removing session', ->
        beforeEach (done) ->
          deletion = helpers.deleteSession(@request, urlFor '/headrest/session')

          deletion.done (res) =>
            done()

        it 'should be 404 when attempting to GET destroyed session', (done) ->
          @request.
            get(urlFor '/headrest/session').
            end (err, res) ->
              expect( res.status ).to.equal 404
              done()

describe 'writing objects', ->
  beforeEach ->
    @request = request.agent()
    @dog =
      name: 'stro'

  describe 'POST', ->

    it 'should return HTTP 201 on successful create', (done) ->
      req = helpers.request(
        @request,
        'post',
        (urlFor '/headrest/animals'),
        @dog
      )

      req.done (res) ->
        expect( res.status ).to.equal 201
        done()

    it 'should use the "animals" section of the url as the _collection', (done) ->
      req = helpers.request(
        @request,
        'post',
        (urlFor '/headrest/animals'),
        @dog
      )

      req.done (res) ->
        obj = JSON.parse(res.body)

        expect( obj._collection ).to.equal 'animals'
        done()

    it 'should set an id on the returned object', (done) ->
      req = helpers.request(
        @request,
        'post',
        (urlFor '/headrest/animals'),
        @dog
      )

      req.done (res) ->
        obj = JSON.parse(res.body)
        expect( obj.id ).not.to.be.undefined
        done()

  describe 'PUT', ->
    beforeEach ->
      @request = request.agent()
      @dog =
        id: 'md5dog'
        name: 'stro'

    context 'when sucessfully updating an existing object', ->
      beforeEach (done) ->
        req = helpers.request(
          @request,
          'post',
          (urlFor '/headrest/put-dogs'),
          @dog
        )

        req.done (res) ->
          if res.status == 201
            done()

      it 'should return a 204', (done) ->
        req = helpers.request(
          @request,
          'put',
          urlFor '/headrest/put-dogs/md5dog',
          name: 'Bistro'
        )

        req.done (res) ->
          expect( res.status ).to.equal 204
          done()

      it 'should have updated the changed field', (done) ->
        req = helpers.request(
          @request,
          'put',
          urlFor('/headrest/put-dogs/md5dog'),
          name: 'Bistro'
        )

        req.done (resp) =>
          get = helpers.request(
            @request,
            'get',
            urlFor('/headrest/put-dogs/md5dog')
          )

          get.done (res) ->
            obj = JSON.parse(res.body)

            expect( obj.name ).to.equal 'Bistro'
            done()

    context 'when object to update does not exist', ->

      it 'should return a 404', (done) ->
        req = helpers.request(
          @request,
          'put',
          (urlFor "/headrest/does-not-exist/does-not-exist"),
          name: 'Bowser'
        )

        req.done (res) ->
          expect( res.status ).to.equal 404
          done()


describe 'reading objects', ->

  describe 'GET index', ->
    beforeEach ->
      @request = request.agent()

    context 'when empty', ->

      it 'should return 200', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/aint-no-dogs-in-here')
        )

        req.done (res) ->
          expect( res.status ).to.equal 200
          done()

      it 'should return empty array', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/aint-no-dogs-in-here')
        )

        req.done (res) ->
          results = JSON.parse(res.body)

          expect( results ).to.be.an 'array'
          expect( results ).to.be.empty
          done()

    context 'when not empty', ->
      beforeEach (done) ->
        dogs = [
          {name: 'Bistrox'},
          {name: 'Browsers'}
        ]

        reqs = for dog in dogs
          helpers.request(
            @request,
            'post',
            (urlFor '/headrest/getdogs'),
            dog
          )

        Q.all(reqs).done -> done()

      it 'should fetch all objects', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/getdogs')
        )

        req.done (res) ->
          dogs = JSON.parse(res.body)

          expect( dogs ).to.have.length 2

          names = (dog.name for dog in dogs)

          expect( names ).to.include 'Bistrox'
          expect( names ).to.include 'Browsers'
          done()

  describe 'GET :id', ->
    beforeEach ->
      @request = request.agent()

    context 'when record with :id does not exist', ->
      it 'should return 404', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/hominy/44')
        )

        req.done (res) ->
          expect( res.status ).to.equal 404
          done()

    context 'when record with :id does exist', ->
      beforeEach (done) ->
        req = helpers.request(
          @request,
          'post',
          (urlFor '/headrest/get-test-pebbles'),
          name: 'fish', id: 'asfd'
        )

        req.done (res) -> done()

      it 'should return 200', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/get-test-pebbles/asfd')
        )

        req.done (res) ->
          expect( res.status ).to.equal 200
          done()

      it 'should return the object', (done) ->
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/get-test-pebbles/asfd')
        )

        req.done (res) ->
          obj = JSON.parse(res.body)
          expect( obj.name ).to.equal 'fish'
          done()

describe 'destroying objects', ->
  beforeEach ->
    @request = request.agent()

  context 'when object does not exist', ->

    it 'should return 404', (done) ->
      req = helpers.request(
        @request,
        'del',
        (urlFor '/headrest/record-does-not-exist')
      )

      req.done (res) ->
        expect( res.status ).to.equal 404
        done()

  context 'when object exists', ->
    beforeEach (done) ->
      req = helpers.request(
        @request,
        'post',
        (urlFor '/headrest/object-for-delete-test'),
        name: 'fish', id: 'asfd'
      )

      req.done (res) -> done()

    it 'should return 204', (done) ->
      req = helpers.request(
        @request,
        'del',
        (urlFor '/headrest/object-for-delete-test/asfd')
      )

      req.done (res) ->
        expect( res.status ).to.equal 204
        done()

    it 'should remove the object', (done) ->
      req = helpers.request(
        @request,
        'del',
        (urlFor '/headrest/object-for-delete-test/asfd')
      )

      req.done (res) =>
        req = helpers.request(
          @request,
          'get',
          (urlFor '/headrest/object-for-delete-test/asfd')
        )

        req.done (res) ->
          expect( res.status ).to.equal 404
          done()

