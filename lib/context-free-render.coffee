utils = require './utils'
CfdgImageEditor = require './cfdg-image-editor'
{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'
url = require 'url'
path = require 'path'
fs = require 'fs-plus'


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
      description: '(Optional) directory where libPng dynamic library should be searched for first.'
    renderTimeoutInMillis:
      type: 'integer'
      default: 3000
      minimum: 0
      description: '(Optional) duration in msec to timeout rendering.'

  subscriptions: null
  platform: null
  tmpPngFiles: []

  activate: (state) ->
    @platform = process.platform
    console.log 'platform: ' + @platform

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'context-free:render': => @render()

    atom.workspace.addOpener @openEditor

  deactivate: ->
    @rmTmpPngFiles()

  render: ->
    console.log 'render'
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

    fileName = path.basename filePath
    console.log 'fileName: ' + fileName
    return unless fileName?

    extName = path.extname(fileName).toLowerCase()
    console.log 'extName: ' + extName
    return unless extName?
    return unless extName is '.cfdg'

    cwd = process.cwd
    env = process.env
    @execCfdg fileName, filePath, cwd, env

  execCfdg: (cfdgFileName, cfdgFilePath, cwd, env) ->
    command = atom.config.get 'language-context-free.cfdgCommandPath'
    console.log "command: #{command}"
    if !command
      atom.confirm
        message: "you need to set 'cfdg Command Path' in the Settings panel."
        buttons: ["OK"]
      return

    unless fs.existsSync command
      commandName = path.basename command
      atom.confirm
        message: "#{command} not found. Make sure `#{commandName}` is installed and on your PATH"
        buttons: ["OK"]
      return

    ldLibraryPath = atom.config.get 'language-context-free.ldLibraryPath'
    console.log "ldLibraryPath: #{ldLibraryPath}"
    if ldLibraryPath
      ldLibraryPathKey = if @platform is 'darwin' then 'DYLD_LIBRARY_PATH' else 'LD_LIBRARY_PATH'
      env[ldLibraryPathKey] = ldLibraryPath

    outFilePath = '/tmp/atom-' + cfdgFileName + ".png"
    args = ['-s', '400', cfdgFilePath, outFilePath]
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
      @tmpPngFiles.push outFilePath
      @sendOpenCommand cfdgFileName, outFilePath

    timeout = atom.config.get 'language-context-free.renderTimeoutInMillis'
    console.log "timeout: #{timeout}"

    cfdgProcess = new BufferedProcess {command, args, options, stdout, stderr, exit}

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

  sendOpenCommand: (cfdgFileName, outFilePath) ->
    uri = utils.uriForFile cfdgFileName, outFilePath
    console.log 'uri: ' + uri
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (openedEditor) ->
      console.log 'openedEditor.getTitle()): ' + openedEditor.getTitle()
      console.log 'openedEditor.getUri()): ' + openedEditor.getUri()
      console.log 'openedEditor.getPath()): ' + openedEditor.getPath()
      previousActivePane.activate()

  openEditor: (uriToOpen) ->
    console.log 'addOpener - uriToOpen: ' + uriToOpen
    try
      {protocol, host, pathname, query} = url.parse uriToOpen, true
    catch error
      console.log 'error'
      return
    console.log 'protocol: ' + protocol + ', host: ' + host + ', pathname: ' + pathname + ', query: ' + query
    return unless protocol is 'context-free-render:'

    cfdgFileName = query['cfdg']
    console.log 'cfdgFileName: ' + cfdgFileName

    try
      pathname = decodeURI pathname if pathname
    catch error
      console.log 'error'
      return
    console.log 'pathname: ' + pathname

    new CfdgImageEditor cfdgFileName, pathname

  rmTmpPngFiles: ->
    for tmpPngFile in @tmpPngFiles
      console.log 'tmpPngFile: ' + tmpPngFile
      utils.rmFile tmpPngFile
