# Node Module for Spell Checking

## Installing

```bash
npm install spellchecker
```

## Docs

```javascript
SpellChecker = require('spellchecker');
```

### SpellChecker.isMisspelled(word)

Check if a word is misspelled.

`word` - String word to check.

Returns `true` if the word is mispelled, `false` otherwise.

### SpellChecker.getCorrectionsForMisspelling(word)

Get the corrections for a misspelled word.

`word` - String word to get corrections for.

Returns a non-null but possibly empty array of string corrections.
