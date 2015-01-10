ContextFreeRender = require '../lib/context-free-render'
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
      console.log "mainModule: #{mainModule}"
      expect(mainModule).toBeDefined()

      spyOn(mainModule, 'render')
      atom.commands.dispatch workspaceElement, 'context-free:render'

      expect(mainModule.render).toHaveBeenCalled()

  describe "when @render unless 'cfdg Command Path' is set", ->
    it "alert with atom.confirm dialog", ->
      console.log "mainModule: #{mainModule}"
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

  describe "when @render unless platform is either 'darwin' or 'linux'", ->
    it "alert with atom.confirm dialog", ->
      console.log "mainModule: #{mainModule}"
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

  # describe "when @render if 'cfdg Command Path' is invalid", ->
  #   it "alert with atom.confirm dialog", ->
  #     console.log "mainModule: #{mainModule}"
  #     expect(mainModule).toBeDefined()
  #
  #     runs ->
  #       atom.workspace.open(path.join(__dirname, 'fixtures', 'Clovers.cfdg'))
  #
  #     waitsFor ->
  #       atom.workspace.getActivePaneItem() instanceof TextEditor
  #
  #     runs ->
  #       expect(atom.workspace.getActivePaneItem().getTitle()).toBe 'Clovers.cfdg'
  #
  #       # atom.config.set "language-context-free.cfdgCommandPath", '/usr/local/bin/cfdg'
  #       atom.config.set "language-context-free.cfdgCommandPath", 'cfdg'
  #       atom.commands.dispatch workspaceElement, 'context-free:render'
