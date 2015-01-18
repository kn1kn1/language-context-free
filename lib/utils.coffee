fs = require 'fs-plus'

# Utilities.
module.exports =
class Utils
  # Create a {String} URI.
  #
  # cfdgFileName: The {String} cfdg file name.
  # filePath: The {String} output file path.
  @uriForFile: (cfdgFileName, filePath) ->
    "context-free-render://filepath#{filePath}?cfdg=#{cfdgFileName}"

  # Copiy a file.
  #
  # source: The {String} file path which will be copied from.
  # target: The {String} file path which will be copied to.
  # cb: The {Function} callback when the copy finished.
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

  # Remove a file.
  #
  # filePath: The {String} file path which will be removed.
  @rmFile: (filePath) ->
    return unless filePath?
    return unless fs.existsSync filePath
    fs.unlinkSync filePath

  # Log all the props of specified object.
  #
  # obj: The {Object}.
  @dumpObj: (obj) ->
    for key, value of obj
      console.log "key: " + key + ", value: " + value
