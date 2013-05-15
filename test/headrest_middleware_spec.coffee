expect   = require('chai').expect
headrestMiddleware = require('../lib/headrest_middleware')


describe 'headrestMiddleware', ->
  it 'should return a function', ->
    expect( headrestMiddleware() ).to.be.a 'function'

  describe 'returned function', ->
    it 'should have arity of 3: request, response, next', ->
      expect( headrestMiddleware().length ).to.equal 3

  describe 'headrest object on request object', ->
    beforeEach ->
      @headrest = headrestMiddleware(
        apiRoot: '/apis/'
      )

    describe 'headrest object', ->

      describe 'collection key', ->

        it 'should not include the apiRoot', (done) ->
          mockRequest =
            path: '/apis/rocks'
          mockResponse = {}

          @headrest mockRequest, mockResponse, ->
            collection = mockRequest.headrest.collection()
            expect( collection ).not.to.have.string 'apis'

            done()

        it 'should include the "rocks" portion', (done) ->
          mockRequest =
            path: '/apis/rocks'
          mockResponse = {}

          @headrest mockRequest, mockResponse, ->
            collection = mockRequest.headrest.collection()
            expect( collection ).to.have.string 'rocks'

            done()

      context 'when processing an "index" action', ->
        # the length of the split path of an index action will always
        # be % 2 == 1
        it 'should not have a record id', (done) ->
          mockRequest =
            path: '/apis/rocks'
          mockResponse = {}

          @headrest mockRequest, mockResponse, ->
            headrest = mockRequest.headrest

            expect( headrest.id() ).to.be.undefined
            done()

        it 'should have a collection name', (done) ->
          mockRequest =
            path: '/apis/rocks'
          mockResponse = {}

          @headrest mockRequest, mockResponse, ->
            headrest = mockRequest.headrest

            expect( headrest.collection() ).
              to.equal 'rocks'
            done()

        context 'with multiple levels of nesting', ->

          beforeEach ->
            @mockRequest =
              path: '/apis/rocks/ffebac/sedimentaries'
            @mockResponse = {}

          it 'should not have a record id', (done) ->
            @headrest @mockRequest, @mockResponse, =>
              headrest = @mockRequest.headrest

              expect( headrest.id() ).to.be.undefined
              done()

          it 'should have a collection name', (done) ->
            @headrest @mockRequest, @mockResponse, =>
              headrest = @mockRequest.headrest

              expect( headrest.collection() ).
                to.equal 'rocks/ffebac/sedimentaries'

              done()

      context 'when processing a POST', ->
        beforeEach ->
          @mockRequest =
            path: '/apis/rocks'
            method: 'POST'
          @mockResponse = {}

        it 'should not have a record id', (done) ->
          @headrest @mockRequest, @mockResponse, =>
            headrest = @mockRequest.headrest

            expect( headrest.id() ).to.be.undefined
            done()

        it 'should have a collection', (done) ->
          @headrest @mockRequest, @mockResponse, =>
            headrest = @mockRequest.headrest

            expect( headrest.collection() ).
              to.equal 'rocks'
            done()

        context 'with multiple levels of nesting', ->
          beforeEach ->
            @mockRequest =
              path: '/apis/rocks/ffebac/sedimentaries'
              method: 'POST'
            @mockResponse = {}

          it 'should not have a record id', (done) ->
            @headrest @mockRequest, @mockResponse, =>
              headrest = @mockRequest.headrest

              expect( headrest.id() ).to.be.undefined
              done()

          it 'should have a collection', (done) ->
            @headrest @mockRequest, @mockResponse, =>
              headrest = @mockRequest.headrest

              expect( headrest.collection() ).
                to.equal 'rocks/ffebac/sedimentaries'
              done()

      context 'when processing a GET for a single resource', ->
        beforeEach ->
          @mockRequest =
            path: '/apis/rocks/4'
            method: 'GET'
          @mockResponse = {}

        it 'should have a record id', (done) ->
          @headrest @mockRequest, @mockResponse, =>
            headrest = @mockRequest.headrest

            expect( headrest.id() ).to.equal '4'
            done()

        it 'should have a collection', (done) ->
          @headrest @mockRequest, @mockResponse, =>
            headrest = @mockRequest.headrest

            expect( headrest.collection() ).
              to.equal 'rocks'
            done()

        context 'with multiple levels of nesting', ->
          beforeEach ->
            @mockRequest =
              path: '/apis/rocks/ffebac/sedimentaries/4'
              method: 'GET'
            @mockResponse = {}

          it 'should have a record id', (done) ->
            @headrest @mockRequest, @mockResponse, =>
              headrest = @mockRequest.headrest

              expect( headrest.id() ).to.equal '4'
              done()

          it 'should have a collection', (done) ->
            @headrest @mockRequest, @mockResponse, =>
              headrest = @mockRequest.headrest

              expect( headrest.collection() ).
                to.equal 'rocks/ffebac/sedimentaries'
              done()








