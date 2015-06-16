require! 'knox'

export setup = ({config}) ->
  exports.ecards = Promise.promisify-all knox.create-client {
    key: config.AWS_S3_KEY
    secret: config.AWS_S3_SECRET
    bucket: config.ECARDS_S3_BUCKET
    region: config.ECARDS_S3_REGION
    secure: false
  }
