CfdgImageEditor = require './cfdg-image-editor'
{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'
url = require 'url'
path = require 'path'
fs = require 'fs-plus'

module.exports = ContextFreeRender =
  config:
    renderTimeoutInMillis:
      type: 'integer'
      default: 3000
      minimum: 0
  subscriptions: null
  tmpPngFiles: []

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'context-free:render': => @render()

    atom.workspace.addOpener @openEditor

  deactivate: ->
    @rmTmpPngFile()

  render: ->
    platform = process.platform
    unless platform is 'darwin'
      atom.confirm
        message: "render not supported in #{platform}."
        buttons: ["Ok"]
      return

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    filePath = editor.getPath()
    console.log('filePath: ' + filePath)
    return unless filePath?

    fileName = path.basename(filePath)
    console.log('fileName: ' + fileName)
    return unless fileName?

    extName = path.extname(fileName).toLowerCase()
    console.log('extName: ' + extName)
    return unless extName?
    return unless extName is '.cfdg'

    packagePath = atom.packages.resolvePackagePath 'language-context-free'
    console.log('packagePath: ' + packagePath)

    cwd = "#{packagePath}/assets/cfdg3/#{platform}"
    env = process.env

    @execChmod cwd, env, (exitcode) =>
      unless exitcode is 0
        atom.confirm
          message: "chmod exited with the wrong return code #{exitcode}"
          buttons: ["Ok"]
        return
      @execCfdg fileName, filePath, cwd, env

  execChmod: (cwd, env, callback) ->
    command = "chmod"
    args = ['+x', 'cfdg']
    options =
      cwd: cwd
      env: env
    stdout = (output) -> console.log(output)
    stderr = (err) -> console.log(err)
    exit = (code) =>
      console.log("#{command} exited with #{code}")
      callback(code)
    chmodProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

  execCfdg: (cfdgFileName, cfdgFilePath, cwd, env) ->
    command = "./cfdg"
    env['DYLD_LIBRARY_PATH'] = 'lib'
    outFilePath = '/tmp/atom-' + cfdgFileName + ".png"
    args = ['-s', '400', cfdgFilePath, outFilePath]
    options =
      cwd: cwd
      env: env
    stdout = (output) -> console.log(output)
    stderr = (err) -> console.log(err)

    done = false
    exit = (code) =>
      console.log("#{command} exited with #{code}")
      done = true
      unless code is 0
        atom.confirm
          message: "#{command} exited with #{code}"
          buttons: ["Ok"]
        return
      @tmpPngFiles.push(outFilePath)
      @sendOpenCommand(cfdgFileName, outFilePath)

    timeout = atom.config.get('language-context-free.renderTimeoutInMillis')
    console.log("timeout: #{timeout}")

    cfdgProcess = new BufferedProcess({command, args, options, stdout, stderr, exit})

    # do not timeout when the setting value is 0
    return unless timeout?
    return if timeout is 0

    callback = () ->
      console.log("done: #{done}")
      unless done
        cfdgProcess.kill()
        atom.confirm
          message: "render cfdg command timeout."
          buttons: ["Ok"]
    setTimeout callback, timeout

  sendOpenCommand: (cfdgFileName, outFilePath) ->
    uri = @uriForFile(cfdgFileName, outFilePath)
    console.log('uri: ' + uri)
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (openedEditor) ->
      console.log('openedEditor.getTitle()): ' + openedEditor.getTitle())
      console.log('openedEditor.getUri()): ' + openedEditor.getUri())
      console.log('openedEditor.getPath()): ' + openedEditor.getPath())
      previousActivePane.activate()

  openEditor: (uriToOpen) ->
    console.log('addOpener - uriToOpen: ' + uriToOpen)
    try
      {protocol, host, pathname, query} = url.parse(uriToOpen, true)
    catch error
      console.log('error')
      return
    console.log('protocol: ' + protocol + ', host: ' + host + ', pathname: ' + pathname + ', query: ' + query)
    return unless protocol is 'context-free-render:'

    cfdgFileName = query['cfdg']
    console.log('cfdgFileName: ' + cfdgFileName)

    try
      pathname = decodeURI(pathname) if pathname
    catch error
      console.log('error')
      return
    console.log('pathname: ' + pathname)

    new CfdgImageEditor(cfdgFileName, pathname)

  uriForFile: (cfdgFileName, filePath) ->
    "context-free-render://filepath#{filePath}?cfdg=#{cfdgFileName}"

  rmTmpPngFile: ->
    for tmpPngFile in @tmpPngFiles
      console.log('tmpPngFile: ' + tmpPngFile)
      @rmFile tmpPngFile

  rmFile: (filePath) ->
    return unless filePath?
    return unless fs.existsSync(filePath)
    fs.unlinkSync(filePath)

  dumpObj: (obj) ->
    for key, value of obj
      console.log ("key: " + key + ", value: " + value)
