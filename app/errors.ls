require! {
  'bluebird': Promise
}

err = (status, reason, details) --> Promise.reject {status, reason, details}

module.exports = errors = {
  err: err
  bad-request: err 400, 'Bad request'
  not-found: err 404, 'Not found'
  forbidden: err 403, 'Forbidden'
}
