require! {
  '../../config'
  '../errors'
  '../id-gen'
  'bluebird': Promise
  'express'
  'knox'
}

s3 = knox.create-client {
  key: config.AWS_S3_KEY
  secret: config.AWS_S3_SECRET
  bucket: config.ECARDS_S3_BUCKET
  region: config.ECARDS_S3_REGION
  secure: false
}

s3 = Promise.promisify-all s3

module.exports = (models, store, config) ->
  app = express.Router!

  app.post '/' (req, res, next) ->
    unless typeof req.body.html is \string then res.promise errors.bad-request 'You must supply html'
    result = id-gen.get-unique store, 'ecard-name'
      .tap (id) ->
        file-name = "/c/#id"
        contents = new Buffer req.body.html
        headers = {
          'Content-Type': 'text/html'
          'x-amz-acl': 'public-read'
        }
        s3.put-buffer-async contents, file-name, headers
          .then (response) ->
            console.log response
      .then (id) ->
        {success: true, file: "/c/#id"}

    res.promise result

