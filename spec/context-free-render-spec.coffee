CfdgImageEditor = require '../lib/cfdg-image-editor'
ContextFreeRender = require '../lib/context-free-render'
utils = require '../lib/utils'
path = require 'path'
{TextEditor} = require 'atom'


# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "ContextFreeRender", ->
  [workspaceElement, activationPromise, editorView, editor, mainModule] = []

  beforeEach ->
    workspaceElement = atom.views.getView atom.workspace

    # Activate the package
    waitsForPromise ->
      atom.packages.activatePackage("language-context-free")
        .then (a) -> mainModule = a.mainModule

  describe "when the language-context-free package is activated", ->
    it "can trigger the context-free:render command", ->
      expect(mainModule).toBeDefined()

      spyOn(mainModule, 'render')
      atom.commands.dispatch workspaceElement, 'context-free:render'

      expect(mainModule.render).toHaveBeenCalled()

    it "can deactivate gracefully", ->
      expect(mainModule).toBeDefined()
      mainModule.deactivate()

  describe "when @render unless 'cfdg Command Path' is set", ->
    it "alert with atom.confirm dialog", ->
      expect(mainModule).toBeDefined()

      runs ->
        atom.workspace.open(path.join(__dirname, 'fixtures', 'Clovers.cfdg'))

      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof TextEditor

      runs ->
        expect(atom.workspace.getActivePaneItem().getTitle()).toBe 'Clovers.cfdg'

        # atom.config.set "language-context-free.cfdgCommandPath", '/usr/local/bin/cfdg'
        spyOn atom, 'confirm'
        atom.commands.dispatch workspaceElement, 'context-free:render'

        confirmArg =
          message: "you need to set 'cfdg Command Path' in the Settings panel."
          buttons: ["OK"]
        expect(atom.confirm).toHaveBeenCalledWith(confirmArg)

  describe "when @render if 'cfdg Command Path' is invalid", ->
    it "alert with atom.confirm dialog", ->
      expect(mainModule).toBeDefined()

      runs ->
        atom.workspace.open(path.join(__dirname, 'fixtures', 'Clovers.cfdg'))

      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof TextEditor

      runs ->
        expect(atom.workspace.getActivePaneItem().getTitle()).toBe 'Clovers.cfdg'

        # atom.config.set "language-context-free.cfdgCommandPath", '/usr/local/bin/cfdg'
        invalidPath = 'CFDGINVALIDPATH'
        atom.config.set "language-context-free.cfdgCommandPath", invalidPath

        spyOn atom, 'confirm'
        atom.commands.dispatch workspaceElement, 'context-free:render'

        fileName = path.basename invalidPath
        confirmArg =
          message: "#{invalidPath} not found. Make sure `#{fileName}` is installed and on your PATH"
          buttons: ["OK"]
        expect(atom.confirm).toHaveBeenCalledWith(confirmArg)

  describe "when @render unless platform is either 'darwin' or 'linux'", ->
    it "alert with atom.confirm dialog", ->
      expect(mainModule).toBeDefined()
      platformWin32 = 'win32'
      mainModule.platform = platformWin32 # change platform to 'win32'

      runs ->
        atom.workspace.open(path.join(__dirname, 'fixtures', 'Clovers.cfdg'))

      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof TextEditor

      runs ->
        expect(atom.workspace.getActivePaneItem().getTitle()).toBe 'Clovers.cfdg'

        spyOn atom, 'confirm'
        atom.commands.dispatch workspaceElement, 'context-free:render'

        confirmArg =
          message: "render not supported in #{platformWin32}."
          buttons: ["OK"]
        expect(atom.confirm).toHaveBeenCalledWith(confirmArg)

  describe "when @sendOpenCommand if render view has not been created for the file", ->
    it "splits the current pane to the right with a view for the file", ->
      expect(mainModule).toBeDefined()
      cfdgFile = 'Clovers.cfdg'
      pngFile = 'Clovers.cfdg.png'

      runs ->
        atom.workspace.open(path.join(__dirname, 'fixtures', cfdgFile))

      waitsFor ->
        atom.workspace.getActivePaneItem() instanceof TextEditor

      runs ->
        expect(atom.workspace.getActivePaneItem().getTitle()).toBe cfdgFile
        mainModule.sendOpenCommand cfdgFile, path.join(__dirname, 'fixtures', pngFile)

      waitsFor ->
        atom.workspace.getPanes().length > 1

      waitsFor ->
        atom.workspace.getPanes()[1].getItems().length > 0

      runs ->
        expect(atom.workspace.getPanes()).toHaveLength 2
        [leftPane, rightPane] = atom.workspace.getPanes()

        expect(leftPane.isActive()).toBe true
        expect(leftPane.getItems()).toHaveLength 1
        expect(leftPane.getActiveItem().getTitle()).toBe cfdgFile

        expect(rightPane.isActive()).toBe false
        expect(rightPane.getItems()).toHaveLength 1

        editor = rightPane.getActiveItem()
        expect(editor).toBeInstanceOf(CfdgImageEditor)
        expect(editor.getTitle()).toBe "#{cfdgFile} Render"
        expPath = path.join(__dirname, 'fixtures', pngFile)
        expect(editor.getPath()).toBe expPath
        expect(editor.getCfdgFileName()).toBe cfdgFile
        expect(editor.getUri()).toBe "context-free-render://filepath#{expPath}?cfdg=#{cfdgFile}"
