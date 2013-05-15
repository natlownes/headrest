class HeadrestMiddleware
  constructor: (@request, apiRoot='') ->
    collectionPath = @_pathWithoutApiRoot(@request.path, apiRoot)
    @fragments     = @_collectionArray(collectionPath)
    @verb          = @request.method

  id: ->
    if @isSingleResourcePath() then @fragments[@fragments.length - 1]

  collection: ->
    if @isSingleResourcePath()
      @fragments[0..-2].join('/')
    else
      @fragments.join('/')

  isIndex: ->
    !@isSingleResourcePath()? and (@verb == 'GET')

  isSingleResourcePath: ->
    (@fragments.length % 2) == 0

  _collectionArray: (path) ->
    list = path.split('/')
    (frag for frag in list when @_isFragmentValid(frag))

  _isFragmentValid: (str) -> str.length > 0

  _pathWithoutApiRoot: (path, apiRoot='') ->
    path.replace(apiRoot, '')


headrestMiddleware = (options={}) ->
  apiRoot = options.apiRoot or '/api/'

  (request, response, next) ->
    request.headrest  = new HeadrestMiddleware(request, apiRoot)

    next()

module.exports = headrestMiddleware

