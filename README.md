# SpellChecker Node Module [![Build Status](https://travis-ci.org/atom/node-spellchecker.svg?branch=master)](https://travis-ci.org/atom/node-spellchecker) [![Build status](https://ci.appveyor.com/api/projects/status/up294b734wagwlaw/branch/master?svg=true)](https://ci.appveyor.com/project/kevinsawicki/node-spellchecker/branch/master)

Native bindings to [NSSpellChecker](https://developer.apple.com/library/mac/#documentation/cocoa/reference/ApplicationKit/Classes/NSSpellChecker_Class/Reference/Reference.html), [Hunspell](http://hunspell.sourceforge.net/), or the [Windows 8 Spell Check API](https://msdn.microsoft.com/en-us/library/windows/desktop/hh869853(v=vs.85).aspx), depending on your platform. Windows 7 and below as well as Linux will rely on Hunspell.

## Installing

```bash
npm install spellchecker
```
**Important**: Must have g++ version greater than 4.6 to succesfully build project. 

## Using

```coffeescript
SpellChecker = require 'spellchecker'
```

### SpellChecker.isMisspelled(word)

Check if a word is misspelled.

`word` - String word to check.

Returns `true` if the word is misspelled, `false` otherwise.

### SpellChecker.getCorrectionsForMisspelling(word)

Get the corrections for a misspelled word.

`word` - String word to get corrections for.

Returns a non-null but possibly empty array of string corrections.

### SpellChecker.add(word)

Adds a word to the dictionary.
When using Hunspell, this will not modify the .dic file; new words must be added each time the spellchecker is created. Use a custom dictionary file.

`word` - String word to add.

Returns nothing.
