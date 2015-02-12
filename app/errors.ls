require! {
  'bluebird': Promise
}

err = (status, reason, details) --> Promise.reject {status, reason, details}

module.exports = errors = {
  err: err
  bad-request: err 400, 'Bad request'
  unauthorized: err 401, 'Unauthorized'
  forbidden: err 403, 'Forbidden'
  not-found: err 404, 'Not found'
  checkit-error: (error) ->
    console.error error
    formatted-errors = for _, checkit-err of error.errors => checkit-err.message
    err 400, 'Validation error', formatted-errors
}
