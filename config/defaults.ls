module.exports = {
  DB_NAME: 'hindquarters'
  DB_PORT: '5432'
  DB_SSL: true
  DB_USER: 'hindquarters'
  MONGO_URL: 'mongodb://localhost:27017/hindquarters'
  PORT: 3000
  SESSION_MAXAGE: 1000 * 60 * 60 * 24 * 365 # 1 year
  SESSION_NAME: 'eak-sess'
  ECARDS_S3_BUCKET: 'eak-ecards'
  ECARDS_S3_REGION: 'eu-west-1'
}
