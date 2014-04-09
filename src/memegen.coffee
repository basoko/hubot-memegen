# Description:
#   Create funny memes using your own image templates
#
# Dependencies:
#   form-data
#   imagemagick
#
# Configuration:
#   HUBOT_MEMEGEN_TEMPLATES_FILE      - File in json format where your templates are defined (example/templates.json)
#   HUBOT_MEMEGEN_IMAGE_BIN_APIKEY    - Api key of the imagebin.ca service
#
# Commands:
#   hubot memegen <template_id> <phrase> - Create the meme usign the template_id and the phrase given
#
# Author:
#   basoko
#

http = require('http')
fs = require('fs')
FormData = require('form-data')
im = require('imagemagick')



module.exports = (robot) ->
  logger = robot.logger

  apikey = process.env.HUBOT_MEMEGEN_IMAGE_BIN_APIKEY
  if not apikey
    logger.error "Not found HUBOT_MEMEGEN_IMAGE_BIN_APIKEY"
    return

  try
    templates = JSON.parse(fs.readFileSync(process.env.HUBOT_MEMEGEN_TEMPLATES_FILE))
    logger.debug templates
  catch error
    logger.error "Problem loading the templates definition. Check HUBOT_MEMEGEN_TEMPLATES_FILE definition and file format."
    return

  class Meme
    constructor: (@apikey, @msg) ->
      @expire = 24 * 60 * 60 * 1000 # One day
      @template = templates[msg.match[1]]
      @filename = "/tmp/_meme_#{new Date().getTime()}.png"
      @phrase = @msg.match[2]

    generate: () ->
      if not @template
        logger.warning "Not found the template: #{@msg.match[1]}"

      orientation = if @template.orientation then @template.orientation.toLowerCase() else "south"

      if @template.marginY
        marginY = @template.marginY
      else
        marginY = '10' # Default margin

      params = ["-background", "#0008", "-fill", "white", "-stroke", "black", "-strokewidth", "2", "-gravity", "center", "-size", "#{@template.w}x#{@template.h}", "caption:#{@phrase}", @template.file, "+swap", "-gravity", orientation, "-geometry", "+0+#{marginY}", "-composite", @filename]

      logger.debug params.join(' ')

      im.convert(params, @upload)

    upload: () =>
      expiration =  new Date(new Date().getTime() + @expire)
      logger.debug expiration

      form = new FormData()
      form.append('key', @apikey)
      form.append('file', fs.createReadStream(@filename))
      form.append('expire', "#{expiration.getDate()}-#{expiration.getMonth()}-#{expiration.getFullYear()}")

      options = {
        host: 'imagebin.ca',
        port: 80,
        path: '/upload.php',
        method: 'POST',
        headers: form.getHeaders()
      }

      request = http.request options

      form.pipe request
      request.on 'response', @processResponse

    processResponse: (res) =>
      logger.debug res.statusCode
      body = ''

      res.on('data', (chunk) ->
        body += chunk;
      )

      res.on('end', () =>
        if res.statusCode == 200
          urlPattern=/url:(.*)/i
          url = body.match(urlPattern)[1]

          @msg.send "#{url}#.png"
        else
          logger.debug "Error Uploading the meme to the web"

        @removeFile()
      )

    removeFile: () =>
      fs.unlink(@filename, (err) => logger.debug err)

  robot.respond /memegen (.*?) ([a-zA-Z\d].*)$/i, (msg) ->
    meme = new Meme apikey, msg
    meme.generate()
