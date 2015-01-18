fs = require 'fs-plus'

module.exports =
class Utils
  @uriForFile: (cfdgFileName, filePath) ->
    "context-free-render://filepath#{filePath}?cfdg=#{cfdgFileName}"

  @copyFile: (source, target, cb) ->
    cbCalled = false

    done = (err) ->
      return if cbCalled
      cb(err)
      cbCalled = true

    rd = fs.createReadStream(source)
    rd.on "error", (err) ->
      done(err)
    wr = fs.createWriteStream(target)
    wr.on "error", (err) ->
      done(err)
    wr.on "close", (err) ->
      done()
    rd.pipe(wr)

  @rmFile: (filePath) ->
    return unless filePath?
    return unless fs.existsSync filePath
    fs.unlinkSync filePath

  @dumpObj: (obj) ->
    for key, value of obj
      console.log "key: " + key + ", value: " + value
