describe '/v1/sessions' ->
  specify 'should return 200' (done) ->
    api.get '/v1/sessions'
      .expect 200, done
