utils = null
Variation = null
VariationHolder = null
CfdgImageEditor = null
url = null
path = null
fs = null
temp = null
os = null

{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'

# Main module of the package.
module.exports = ContextFreeRender =
  config:
    cfdgCommandPath:
      type: 'string'
      title: 'cfdg Command Path'
      default: ''
      description: 'path of cfdg command.'
    ldLibraryPath:
      title: 'LD_LIBRARY_PATH'
      type: 'string'
      default: ''
      description: '(Optional) directory where libPng dynamic library should \
        be searched for first.'
    renderTimeoutInMillis:
      type: 'integer'
      default: 3000
      minimum: 0
      description: '(Optional) duration in msec to timeout rendering.'
    width:
      type: 'integer'
      default: 500
      minimum: 0
      description: '(Optional) width in pixels(png).'
    height:
      type: 'integer'
      default: 500
      minimum: 0
      description: '(Optional) height in pixels(png).'
    variation:
      type: 'string'
      default: ''
      description: "variation code ('A' - 'ZZZZZZ')."

  subscriptions: null
  platform: null
  tempDirPah: null

  variation: null
  addVariation: false
  selfChange: false

  activate: (state) ->
    Variation ?= require './variation'
    variationStr = atom.config.get 'language-context-free.variation'
    unless Variation.isValid variationStr
      variationStr = 'A'
      atom.config.set 'language-context-free.variation', variationStr
    @variation = new Variation variationStr
    @addVariation = false

    atom.config.onDidChange 'language-context-free.variation', (event) =>
      unless Variation.isValid event.newValue
        atom.config.set 'language-context-free.variation', event.oldValue
        return
      @variation = new Variation event.newValue
      if @selfChange
        # changed by this process
        @selfChange = false
      else
        # changed from Settings panel
        @addVariation = false

    # Events subscribed to in atom's system can be easily cleaned up
    # with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'context-free:render': => @render()

    atom.workspace.addOpener @openEditor

  deactivate: ->
    @subscriptions.dispose()

  # Render image from cfdg file.
  render: ->
    console.log 'render'

    unless @platform
      @platform = process.platform
      console.log 'platform: ' + @platform

      temp ?= require 'temp'
      # WORKAROUND for linux tmp dir
      if @platform is 'linux'
        path ?= require 'path'
        os ?= require 'os'
        temp.dir = path.resolve os.tmpdir()

      temp.track()
      console.log 'temp.dir: ' + temp.dir
      @tempDirPah = temp.mkdirSync 'atom-cfdg-'
      console.log 'tempDirPah: ' + @tempDirPah

    unless @platform is 'darwin' or @platform is 'linux'
      atom.confirm
        message: "render not supported in #{@platform}."
        buttons: ["OK"]
      return

    editor = atom.workspace.getActiveTextEditor()
    console.log 'editor: ' + editor
    return unless editor?

    filePath = editor.getPath()
    console.log 'filePath: ' + filePath
    return unless filePath?

    path ?= require 'path'
    fileName = path.basename filePath
    console.log 'fileName: ' + fileName
    return unless fileName?

    extName = path.extname(fileName).toLowerCase()
    console.log 'extName: ' + extName
    return unless extName?
    return unless extName is '.cfdg'

    if @addVariation
      @variation.add1()
      @selfChange = true
      atom.config.set 'language-context-free.variation', @variation.value
    else
      @addVariation = true

    cwd = process.cwd
    env = process.env
    @execCfdg fileName, filePath, @variation.value, cwd, env

  # Execute cfdg command.
  #
  # cfdgFileName: The {String} name of cfdg file.
  # cfdgFilePath: The {String} path of cfdg file.
  # variation: The {String} variation code.
  # cwd: The {String} working directory to execute the process.
  # env: The {Object} containing the user environment.
  execCfdg: (cfdgFileName, cfdgFilePath, variation, cwd, env) ->
    command = atom.config.get 'language-context-free.cfdgCommandPath'
    console.log "command: #{command}"
    if !command
      atom.confirm
        message: "you need to set 'cfdg Command Path' in the Settings panel."
        buttons: ["OK"]
      return

    fs ?= require 'fs-plus'
    unless fs.existsSync command
      commandName = path.basename command
      atom.confirm
        message: "#{command} not found. Make sure `#{commandName}` is \
          installed and on your PATH"
        buttons: ["OK"]
      return

    ldLibraryPath = atom.config.get 'language-context-free.ldLibraryPath'
    console.log "ldLibraryPath: #{ldLibraryPath}"
    if ldLibraryPath
      ldLibraryPathKey = if @platform is 'darwin' then 'DYLD_LIBRARY_PATH' else
        'LD_LIBRARY_PATH'
      env[ldLibraryPathKey] = ldLibraryPath

    width = atom.config.get 'language-context-free.width'
    unless width
      width = 500
    height = atom.config.get 'language-context-free.height'
    unless height
      height = 500

    outFilePath = path.join @tempDirPah, "#{cfdgFileName}.png"
    console.log "outFilePath: #{outFilePath}"
    args = ['-w', width, '-h', height, '-v', variation, cfdgFilePath, outFilePath]
    options =
      cwd: cwd
      env: env
    stdout = (output) -> console.log output
    stderr = (err) -> console.log err

    done = false
    exit = (code) =>
      console.log "#{command} exited with #{code}"
      done = true
      unless code is 0
        atom.confirm
          message: "#{command} exited with #{code}"
          buttons: ["OK"]
        return

      VariationHolder ?= require './variation-holder'
      VariationHolder.putVariation(outFilePath, variation)
      @sendOpenCommand cfdgFileName, outFilePath

    timeout = atom.config.get 'language-context-free.renderTimeoutInMillis'
    console.log "timeout: #{timeout}"

    cfdgProcess =
      new BufferedProcess {command, args, options, stdout, stderr, exit}

    # do not timeout when the setting value is 0
    return unless timeout?
    return if timeout is 0

    callback = ->
      console.log "done: #{done}"
      unless done
        cfdgProcess.kill()
        atom.confirm
          message: "render cfdg command timeout."
          buttons: ["OK"]
    setTimeout callback, timeout

  # Send an intent to open new editor to the atom workspace.
  #
  # cfdgFileName: The {String} name of cfdg file.
  # outFilePath: The {String} path of image output file.
  sendOpenCommand: (cfdgFileName, outFilePath) ->
    utils ?= require './utils'
    uri = utils.uriForFile cfdgFileName, outFilePath
    console.log 'uri: ' + uri
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true)
      .done (openedEditor) ->
        console.log 'openedEditor.getTitle()): ' + openedEditor.getTitle()
        console.log 'openedEditor.getURI()): ' + openedEditor.getURI()
        console.log 'openedEditor.getPath()): ' + openedEditor.getPath()
        previousActivePane.activate()

  # Create a {CfdgImageEditor} and open the image.
  #
  # uriToOpen: The {String} uri.
  openEditor: (uriToOpen) ->
    console.log 'addOpener - uriToOpen: ' + uriToOpen
    try
      url ?= require 'url'
      {protocol, host, pathname, query} = url.parse uriToOpen, true
    catch error
      console.log 'error'
      return
    console.log 'protocol: ' + protocol + ', host: ' + host + ', pathname: ' +
      pathname + ', query: ' + query
    return unless protocol is 'context-free-render:'

    cfdgFileName = query['cfdg']
    console.log 'cfdgFileName: ' + cfdgFileName

    try
      pathname = decodeURI pathname if pathname
    catch error
      console.log 'error'
      return
    console.log 'pathname: ' + pathname

    CfdgImageEditor ?= require './cfdg-image-editor'
    new CfdgImageEditor cfdgFileName, pathname
