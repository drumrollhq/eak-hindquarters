require! 'joi'

export body = joi.object!.keys {
  html: joi.string!.required!
}

export handler = ({body, services: {s3, ids}}) ->
  ids.get-unique \ecard-name
    .tap (id) ->
      file-name = "/c/#id"
      contents = new Buffer body.html
      headers = {
        'Content-Type': 'text/html'
        'x-amz-acl': 'public-read'
      }
      s3.ecards.put-buffer-async contents, file-name, headers
    .then (id) ->
      {success: true, file: "/c/#id"}
