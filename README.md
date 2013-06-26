# SpellChecker Node Module

Native bindings to [NSSpellChecker](https://developer.apple.com/library/mac/#documentation/cocoa/reference/ApplicationKit/Classes/NSSpellChecker_Class/Reference/Reference.html).

## Installing

```bash
npm install spellchecker
```

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
