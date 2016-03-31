# Context Free support in Atom

Adds syntax highlighting and snippets to Context Free files in Atom.

Originally [converted](http://atom.io/docs/latest/converting-a-text-mate-bundle)
from the [Context Free TextMate bundle](https://github.com/textmate/context-free.tmbundle)
and merged with the [Context Free 3 Bundle for TextMate 1.x](https://github.com/Royaljerry/cfdg-3-bundle-for-textmate-1-x).

Contributions are greatly appreciated. Please fork this repository and open a
pull request to add snippets, make grammar tweaks, etc.

## Rendering (OS X and Linux)

If you have cfdg (Context Free Command-Line Version), you can render Context Free files.

Please set "cfdg Command Path" setting and render *.cfdg files via the shortcut `ctrl-shift-r` or the menu `Packages > Context Free > Render`.

![Language Context Free - Rendering Screenshot](https://raw.githubusercontent.com/kn1kn1/language-context-free/master/rendering.png)

**Please note:** In the example above I installed cfdg from [the Homebrew-cfdg Tap repository](https://github.com/kn1kn1/homebrew-cfdg) and set `/usr/local/bin/cfdg` as "cfdg Command Path".

![cfdg Command Path setting](https://raw.githubusercontent.com/kn1kn1/language-context-free/master/settings.png)

## Build Status

[![Build Status](https://travis-ci.org/kn1kn1/language-context-free.svg?branch=master)](https://travis-ci.org/kn1kn1/language-context-free)
[![Circle CI](https://circleci.com/gh/kn1kn1/language-context-free.png?style=shield)](https://circleci.com/gh/kn1kn1/language-context-free)
[![wercker status](https://app.wercker.com/status/005e3657c1a81d0fcaceafa0980fcb99/m "wercker status")](https://app.wercker.com/project/bykey/005e3657c1a81d0fcaceafa0980fcb99)
