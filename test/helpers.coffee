Q = require 'q'

helpers =
  loginUser: (agent, path) ->
    deferred = Q.defer()
    agent.
      post(path).
      send(username: 'Billy Martin', password: 'brawlin').
      end (err, resp) ->
        if err
          deferred.reject(err, resp)
        else
          deferred.resolve(resp)

    deferred.promise

  sessionDeleted: (agent, path) ->
    # do a GET to path, ensure we
    # get a 404 back, meaning session
    # is deleted
    deferred = Q.defer()
    agent.
      get(path).
      end (err, resp) ->
        status = resp.status
        if 404 == status
          deferred.resolve(resp)
        else
          deferred.reject(resp)

    deferred.promise

  deleteSession:  (agent, path) ->
    deferred = Q.defer()
    agent.
      del(path).
      end (err, res) =>
        isDeleted = helpers.sessionDeleted(agent, path)

        isDeleted.done -> deferred.resolve(res)
        isDeleted.fail -> deferred.reject(res)

    deferred.promise

  request: (agent, method, path, body) ->
    deferred = Q.defer()
    req = agent[method](path)

    req.
      send(body).
      set('Accept', 'application/json').
      end (err, resp) ->
        if err
          deferred.reject(resp)
        else
          deferred.resolve(resp)

    deferred.promise


module.exports = helpers


