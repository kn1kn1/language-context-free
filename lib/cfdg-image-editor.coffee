utils = require './utils'
path = require 'path'
fs = require 'fs-plus'
{File} = require 'pathwatcher'
{CompositeDisposable} = require 'atom'

# Editor model for an image file
module.exports =
class CfdgImageEditor
  atom.deserializers.add(this)

  @deserialize: ({cfdgFileName, filePath}) ->
    if fs.isFileSync(filePath)
      new CfdgImageEditor(cfdgFileName, filePath)
    else
      console.warn "Could not deserialize image editor for path '#{filePath}' because that file no longer exists"

  constructor: (cfdgFileName, filePath) ->
    @cfdgFileName = cfdgFileName
    @file = new File(filePath)
    @subscriptions = new CompositeDisposable()

  serialize: ->
    {cfdgFileName: @cfdgFileName, filePath: @getPath(), deserializer: @constructor.name}

  getViewClass: ->
    require './cfdg-image-editor-view'

  # Register a callback for when the image file changes
  onDidChange: (callback) ->
    changeSubscription = @file.onDidChange(callback)
    @subscriptions.add(changeSubscription)
    changeSubscription

  # Register a callback for whne the image's title changes
  onDidChangeTitle: (callback) ->
    renameSubscription = @file.onDidRename(callback)
    @subscriptions.add(renameSubscription)
    renameSubscription

  destroy: ->
    @subscriptions.dispose()

  # Retrieves the filename of the open file.
  #
  # This is `'untitled'` if the file is new and not saved to the disk.
  #
  # Returns a {String}.
  getTitle: ->
    if @cfdgFileName
      @cfdgFileName + ' Render'
    else
      'untitled'

  # Retrieves the URI of the image.
  #
  # Returns a {String}.
  getUri: ->
    filepath = @file.getPath()
    utils.uriForFile(@cfdgFileName, filepath)

  # Retrieves the absolute path to the image.
  #
  # Returns a {String} path.
  getPath: -> @file.getPath()

  # Compares two {ImageEditor}s to determine equality.
  #
  # Equality is based on the condition that the two URIs are the same.
  #
  # Returns a {Boolean}.
  isEqual: (other) ->
    other instanceof CfdgImageEditor and @getUri() is other.getUri()

  getCfdgFileName: -> @cfdgFileName
