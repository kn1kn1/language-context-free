_ = require 'underscore-plus'
path = require 'path'
fs = require 'fs-plus'
{$, ScrollView} = require 'atom-space-pen-views'
{Emitter, CompositeDisposable} = require 'atom'

# View that renders the image of an {ImageEditor}.
module.exports =
class CfdgImageEditorView extends ScrollView
  @content: ->
    @div class: 'cfdg-image-view', tabindex: -1, =>
      @div class: 'cfdg-image-container', =>
        @div class: 'cfdg-image-container-cell', =>
          @img outlet: 'image'

  initialize: (@editor) ->
    super
    @emitter = new Emitter

  attached: ->
    @disposables = new CompositeDisposable

    @loaded = false
    @image.hide()
    @updateImageUri()

    @disposables.add @editor.onDidChange => @updateImageUri()
    @disposables.add atom.commands.add @element,
      'core:save-as': (event) =>
        event.stopPropagation()
        @saveAs()
      'image-view:reload': => @updateImageUri()
      'image-view:zoom-in': => @zoomIn()
      'image-view:zoom-out': => @zoomOut()
      'image-view:reset-zoom': => @resetZoom()

    @image.load =>
      @originalHeight = @image.height()
      @originalWidth = @image.width()
      @loaded = true
      @image.show()
      @emitter.emit 'did-load'

  onDidLoad: (callback) ->
    @emitter.on 'did-load', callback

  detached: ->
    @disposables.dispose()

  updateImageUri: ->
    @image.attr('src', "#{@editor.getPath()}?time=#{Date.now()}")

  # Retrieves this view's pane.
  #
  # Returns a {Pane}.
  getPane: ->
    @parents('.pane').view()

  # Zooms the image out by 10%.
  zoomOut: ->
    @adjustSize(0.9)

  # Zooms the image in by 10%.
  zoomIn: ->
    @adjustSize(1.1)

  # Zooms the image to its normal width and height.
  resetZoom: ->
    return unless @loaded and @isVisible()

    @image.width(@originalWidth)
    @image.height(@originalHeight)

  # Adjust the size of the image by the given multiplying factor.
  #
  # factor - A {Number} to multiply against the current size.
  adjustSize: (factor) ->
    return unless @loaded and @isVisible()

    newWidth = @image.width() * factor
    newHeight = @image.height() * factor
    @image.width(newWidth)
    @image.height(newHeight)

  # Changes the background color of the image view.
  #
  # color - A {String} that is a valid CSS hex color.
  changeBackground: (color) ->
    return unless @loaded and @isVisible() and color
    # TODO: in the future, probably validate the color
    @image.css 'background-color', color

  saveAs: ->
    return if @loading

    srcFilePath = @editor.getPath()
    console.log('srcFilePath: ' + srcFilePath)
    return unless srcFilePath?

    projectPath = atom.project.getPath()
    console.log('projectPath: ' + projectPath)
    cfdgFileName = @editor.getCfdgFileName()
    unless cfdgFileName?
      cfdgFileName = 'untitled'
    saveFilePath = path.join(projectPath, cfdgFileName + '.png')
    console.log('saveFilePath: ' + saveFilePath)

    if dstFilePath = atom.showSaveDialogSync(saveFilePath)
      @copyFile srcFilePath, dstFilePath, (err) ->
        unless err?
          atom.workspace.open(dstFilePath)
        else
          atom.confirm
            message: 'error: ' + err
            buttons: ["Ok"]

  copyFile: (source, target, cb) ->
    cbCalled = false;

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
