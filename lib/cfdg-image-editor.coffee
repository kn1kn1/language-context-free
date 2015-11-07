utils = require './utils'
Variation = require './variation'
VariationHolder = require './variation-holder'
path = require 'path'
fs = require 'fs-plus'
{File, CompositeDisposable} = require 'atom'

# Editor model for an image file.
module.exports =
class CfdgImageEditor
  atom.deserializers.add(this)

  @deserialize: ({cfdgFileName, filePath}) ->
    if fs.isFileSync(filePath)
      new CfdgImageEditor(cfdgFileName, filePath)
    else
      console.warn "Could not deserialize image editor for path '#{filePath}' \
        because that file no longer exists"

  constructor: (cfdgFileName, filePath) ->
    @cfdgFileName = cfdgFileName
    @file = new File(filePath)
    @subscriptions = new CompositeDisposable()

  serialize: ->
    cfdgFileName: @cfdgFileName,
    filePath: @getPath(),
    deserializer: @constructor.name

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
    @getURI()

  # Retrieves the URI of the image.
  #
  # Returns a {String}.
  getURI: ->
    filepath = encodeURI(@getPath()).replace(/#/g, '%23').replace(/\?/g, '%3F')
#    filepath = @file.getPath()
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
    other instanceof CfdgImageEditor and @getURI() is other.getURI()

  # Retrieves the name of cfdg file.
  #
  # Returns a {String}.
  getCfdgFileName: -> @cfdgFileName

  # Retrieves the variation code of this image.
  #
  # Returns a {String}.
  getVariation: -> VariationHolder.getVariation(@getPath())

  # Save a copy of this image.
  saveAs: ->
    srcFilePath = @getPath()
    console.log 'srcFilePath: ' + srcFilePath
    return unless srcFilePath?

    paths = atom.project.getPaths()
    console.log 'paths: ' + paths
    return unless paths?
    return if paths.length < 1

    projectPath = paths[0]
    console.log 'projectPath: ' + projectPath
    cfdgFileName = @getCfdgFileName()
    unless cfdgFileName?
      cfdgFileName = 'untitled'
    saveFilePath = path.join projectPath, "#{cfdgFileName}.png"
    console.log 'saveFilePath: ' + saveFilePath

    if dstFilePath = atom.showSaveDialogSync saveFilePath
      utils.copyFile srcFilePath, dstFilePath, (err) ->
        unless err?
          atom.workspace.open dstFilePath
        else
          atom.confirm
            message: 'error: ' + err
            buttons: ["Ok"]
