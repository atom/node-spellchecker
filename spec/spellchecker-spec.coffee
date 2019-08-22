{Spellchecker, ALWAYS_USE_HUNSPELL} = require '../lib/spellchecker'
path = require 'path'

enUS = 'A robot is a mechanical or virtual artificial agent, usually an electronic machine'
deDE = 'Ein Roboter ist eine technische Apparatur, die üblicherweise dazu dient, dem Menschen mechanische Arbeit abzunehmen.'
frFR = 'Les robots les plus évolués sont capables de se déplacer et de se recharger par eux-mêmes'

defaultLanguage = if process.platform is 'darwin' then '' else 'en_US'
dictionaryDirectory = path.join(__dirname, 'dictionaries')

# Because we are dealing with C++ and buffers, we want
# to make sure the user doesn't pass in a string that
# causes a buffer overrun. We limit our buffers to
# 256 characters (64-character word in UTF-8).
maximumLength1Byte = 'a'.repeat(256)
maximumLength2Byte = 'ö'.repeat(128)
maximumLength3Byte = 'ऐ'.repeat(85)
maximumLength4Byte = '𐅐'.repeat(64)
invalidLength1Byte = maximumLength1Byte + 'a'
invalidLength2Byte = maximumLength2Byte + 'ö'
invalidLength3Byte = maximumLength3Byte + 'ऐ'
invalidLength4Byte = maximumLength4Byte + '𐄇'

maximumLength1BytePair = [maximumLength1Byte, maximumLength1Byte].join " "
maximumLength2BytePair = [maximumLength2Byte, maximumLength2Byte].join " "
maximumLength3BytePair = [maximumLength3Byte, maximumLength3Byte].join " "
maximumLength4BytePair = [maximumLength4Byte, maximumLength4Byte].join " "
invalidLength1BytePair = [invalidLength1Byte, invalidLength1Byte].join " "
invalidLength2BytePair = [invalidLength2Byte, invalidLength2Byte].join " "
invalidLength3BytePair = [invalidLength3Byte, invalidLength3Byte].join " "
invalidLength4BytePair = [invalidLength4Byte, invalidLength4Byte].join " "

spellType = null
spellIndex = null

for testAlwaysUseHunspell in [true, false]
  describe 'SpellChecker', ->
    describe '.setDictionary', ->
      beforeEach ->
        @fixture = buildSpellChecker()

      it 'returns true for en_US', ->
        @fixture.setDictionary('en_US', dictionaryDirectory)

      it 'returns true for de_DE_frami', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        @fixture.setDictionary('de_DE_frami', dictionaryDirectory)

      it 'returns true for de_DE', ->
        @fixture.setDictionary('en_US', dictionaryDirectory)

      it 'returns true for fr', ->
        @fixture.setDictionary('fr', dictionaryDirectory)

    describe '.isMisspelled(word)', ->
      beforeEach ->
        @fixture = buildSpellChecker()
        @fixture.setDictionary defaultLanguage, dictionaryDirectory

      it 'returns true if the word is mispelled', ->
        @fixture.setDictionary('en_US', dictionaryDirectory)
        expect(@fixture.isMisspelled('wwoorrddd')).toBe true

      it 'returns false if the word is not mispelled: word', ->
        @fixture.setDictionary('en_US', dictionaryDirectory)
        expect(@fixture.isMisspelled('word')).toBe false

      it 'returns false if the word is not mispelled: cheese', ->
        @fixture.setDictionary('en_US', dictionaryDirectory)
        expect(@fixture.isMisspelled('cheese')).toBe false

      it 'returns true if Latin German word is misspelled with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('Kine')).toBe true

      it 'returns true if Latin German word is misspelled with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('Kine')).toBe true

      it 'returns false if Latin German word is not misspelled with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('Nacht')).toBe false

      it 'returns false if Latin German word is not misspelled with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('Nacht')).toBe false

      it 'returns true if Unicode German word is misspelled with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('möchtzn')).toBe true

      it 'returns true if Unicode German word is misspelled with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('möchtzn')).toBe true

      it 'returns false if Unicode German word is not misspelled with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('vermöchten')).toBe false

      it 'returns false if Unicode German word is not misspelled with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        expect(@fixture.isMisspelled('vermöchten')).toBe false

      it 'throws an exception when no word specified', ->
        expect(-> @fixture.isMisspelled()).toThrow()

      it 'returns true for a string of 256 1-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(maximumLength1Byte)).toBe true

      it 'returns true for a string of 128 2-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(maximumLength2Byte)).toBe true

      it 'returns true for a string of 85 3-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(maximumLength3Byte)).toBe true

      it 'returns true for a string of 64 4-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(maximumLength4Byte)).toBe true

      it 'returns false for a string of 257 1-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(invalidLength1Byte)).toBe false

      it 'returns false for a string of 65 2-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(invalidLength2Byte)).toBe false

      it 'returns false for a string of 86 3-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(invalidLength3Byte)).toBe false

      it 'returns false for a string of 65 4-byte characters', ->
        if process.platform is 'linux'
          expect(@fixture.isMisspelled(invalidLength4Byte)).toBe false

    describe '.checkSpelling(string)', ->
      beforeEach ->
        @fixture = buildSpellChecker()
        @fixture.setDictionary defaultLanguage, dictionaryDirectory

      it 'automatically detects languages on OS X', ->
        return unless process.platform is 'darwin'

        expect(@fixture.checkSpelling(enUS)).toEqual []
        expect(@fixture.checkSpelling(deDE)).toEqual []
        expect(@fixture.checkSpelling(frFR)).toEqual []

      it 'correctly switches languages', ->
        expect(@fixture.setDictionary('en_US', dictionaryDirectory)).toBe true
        expect(@fixture.checkSpelling(enUS)).toEqual []
        expect(@fixture.checkSpelling(deDE)).not.toEqual []
        expect(@fixture.checkSpelling(frFR)).not.toEqual []

        # de_DE_frami is invalid outside of Hunspell dictionaries.
        if spellType is 'hunspell'
          if @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
            expect(@fixture.checkSpelling(enUS)).not.toEqual []
            expect(@fixture.checkSpelling(deDE)).toEqual []
            expect(@fixture.checkSpelling(frFR)).not.toEqual []

        if @fixture.setDictionary('de_DE', dictionaryDirectory)
          expect(@fixture.checkSpelling(enUS)).not.toEqual []
          expect(@fixture.checkSpelling(deDE)).toEqual []
          expect(@fixture.checkSpelling(frFR)).not.toEqual []

        @fixture = buildSpellChecker()
        if @fixture.setDictionary('fr_FR', dictionaryDirectory)
          expect(@fixture.checkSpelling(enUS)).not.toEqual []
          expect(@fixture.checkSpelling(deDE)).not.toEqual []
          expect(@fixture.checkSpelling(frFR)).toEqual []

      it 'returns an array of character ranges of misspelled words', ->
        string = 'cat caat dog dooog'

        expect(@fixture.checkSpelling(string)).toEqual [
          {start: 4, end: 8},
          {start: 13, end: 18},
        ]

      it 'returns an array of character ranges of misspelled German words with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true

        string = 'Kein Kine vermöchten möchtzn'

        expect(@fixture.checkSpelling(string)).toEqual [
          {start: 5, end: 9},
          {start: 21, end: 28},
        ]

      it 'returns an array of character ranges of misspelled German words with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true

        string = 'Kein Kine vermöchten möchtzn'

        expect(@fixture.checkSpelling(string)).toEqual [
          {start: 5, end: 9},
          {start: 21, end: 28},
        ]

      it 'returns an array of character ranges of misspelled French words', ->
        expect(@fixture.setDictionary('fr', dictionaryDirectory)).toBe true

        string = 'Française Françoize'

        expect(@fixture.checkSpelling(string)).toEqual [
          {start: 10, end: 19},
        ]

      it 'accounts for UTF16 pairs', ->
        string = '😎 cat caat dog dooog'

        expect(@fixture.checkSpelling(string)).toEqual [
          {start: 7, end: 11},
          {start: 16, end: 21},
        ]

      it "accounts for other non-word characters", ->
        string = "'cat' (caat. <dog> :dooog)"
        expect(@fixture.checkSpelling(string)).toEqual [
          {start: 7, end: 11},
          {start: 20, end: 25},
        ]

      it 'does not treat non-english letters as word boundaries', ->
        @fixture.add('cliché')
        expect(@fixture.checkSpelling('what cliché nonsense')).toEqual []
        @fixture.remove('cliché')

      it 'handles words with apostrophes', ->
        string = "doesn't isn't aint hasn't"
        expect(@fixture.checkSpelling(string)).toEqual [
          {start: string.indexOf("aint"), end: string.indexOf("aint") + 4}
        ]

        string = "you say you're 'certain', but are you really?"
        expect(@fixture.checkSpelling(string)).toEqual []

        string = "you say you're 'sertan', but are you really?"
        expect(@fixture.checkSpelling(string)).toEqual [
          {start: string.indexOf("sertan"), end: string.indexOf("',")}
        ]

      it 'handles invalid inputs', ->
        fixture = @fixture
        expect(fixture.checkSpelling('')).toEqual []
        expect(-> fixture.checkSpelling()).toThrow('Bad argument')
        expect(-> fixture.checkSpelling(null)).toThrow('Bad argument')
        expect(-> fixture.checkSpelling({})).toThrow('Bad argument')

      it 'returns values for a pair of 256 1-byte character strings', ->
        if process.platform is 'linux'
          expect(@fixture.checkSpelling(maximumLength1BytePair)).toEqual [
            {start: 0, end: 256},
            {start: 257, end: 513},
          ]

      it 'returns values for a string of 128 2-byte character strings', ->
        if process.platform is 'linux'
          expect(@fixture.checkSpelling(maximumLength2BytePair)).toEqual [
            {start: 0, end: 128},
            {start: 129, end: 257},
          ]

      it 'returns values for a string of 85 3-byte character strings', ->
        if process.platform is 'linux'
          expect(@fixture.checkSpelling(maximumLength3BytePair)).toEqual [
            {start: 0, end: 85},
            {start: 86, end: 171},
          ]

      # # Linux doesn't seem to handle 4-byte encodings, so this test is just to
      # # comment that fact.
      # xit 'returns values for a string of 64 4-byte character strings', ->
      #   expect(@fixture.checkSpelling(maximumLength4BytePair)).toEqual [
      #     {start: 0, end: 128},
      #     {start: 129, end: 257},
      #   ]

      it 'returns nothing for a pair of 257 1-byte character strings', ->
        if process.platform is 'linux'
          expect(@fixture.checkSpelling(invalidLength1BytePair)).toEqual []

      it 'returns nothing for a pair of 129 2-byte character strings', ->
        if process.platform is 'linux'
          expect(@fixture.checkSpelling(invalidLength2BytePair)).toEqual []

      it 'returns nothing for a pair of 86 3-byte character strings', ->
        if process.platform is 'linux'
          expect(@fixture.checkSpelling(invalidLength3BytePair)).toEqual []

      it 'returns nothing for a pair of 65 4-byte character strings', ->
        if process.platform is 'linux'
          expect(@fixture.checkSpelling(invalidLength4BytePair)).toEqual []

      it 'returns values for a pair of 256 1-byte character strings with encoding', ->
        if process.platform is 'linux'
          # de_DE_frami is invalid outside of Hunspell dictionaries.
          return unless spellType is 'hunspell'

          @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
          expect(@fixture.checkSpelling(maximumLength1BytePair)).toEqual [
            {start: 0, end: 256},
            {start: 257, end: 513},
          ]

      it 'returns values for a string of 128 2-byte character strings with encoding', ->
        if process.platform is 'linux'
          # de_DE_frami is invalid outside of Hunspell dictionaries.
          return unless spellType is 'hunspell'

          @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
          expect(@fixture.checkSpelling(maximumLength2BytePair)).toEqual [
            {start: 0, end: 128},
            {start: 129, end: 257},
          ]

      it 'returns values for a string of 85 3-byte character strings with encoding', ->
        if process.platform is 'linux'
          # de_DE_frami is invalid outside of Hunspell dictionaries.
          return unless spellType is 'hunspell'

          @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
          @fixture.checkSpelling(invalidLength3BytePair)

      # # Linux doesn't seem to handle 4-byte encodings
      #it 'returns values for a string of 64 4-byte character strings with encoding', ->
      #  # de_DE_frami is invalid outside of Hunspell dictionaries.
      #  return unless spellType is 'hunspell'

      #  @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
      #  expect(@fixture.checkSpelling(maximumLength4BytePair)).toEqual [
      #    {start: 0, end: 128},
      #    {start: 129, end: 257},
      #  ]

      it 'returns nothing for a pair of 257 1-byte character strings with encoding', ->
        if process.platform is not 'linux'
          # de_DE_frami is invalid outside of Hunspell dictionaries.
          return unless spellType is 'hunspell'

          @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
          expect(@fixture.checkSpelling(maximumLength2BytePair)).toEqual []

      it 'returns nothing for a pair of 129 2-byte character strings with encoding', ->
        return if process.platform is not 'linux'
        # We are only testing for allocation errors.
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
        @fixture.checkSpelling(invalidLength2BytePair)

      it 'returns nothing for a pair of 86 3-byte character strings with encoding', ->
        return if process.platform is not 'linux'
        # We are only testing for allocation errors.
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
        @fixture.checkSpelling(invalidLength3BytePair)

      it 'returns nothing for a pair of 65 4-byte character strings with encoding', ->
        return if process.platform is not 'linux'
        # We are only testing for allocation errors.
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        @fixture.setDictionary('de_DE_frami', dictionaryDirectory)
        @fixture.checkSpelling(invalidLength4BytePair)

    describe '.checkSpellingAsync(string)', ->
      beforeEach ->
        @fixture = buildSpellChecker()
        @fixture.setDictionary defaultLanguage, dictionaryDirectory

      it 'returns an array of character ranges of misspelled words', ->
        string = 'cat caat dog dooog'
        ranges = null

        @fixture.checkSpellingAsync(string).then (r) -> ranges = r

        waitsFor -> ranges isnt null

        runs ->
          expect(ranges).toEqual [
            {start: 4, end: 8}
            {start: 13, end: 18}
          ]

      it 'handles invalid inputs', ->
        expect(=> @fixture.checkSpelling()).toThrow('Bad argument')
        expect(=> @fixture.checkSpelling(null)).toThrow('Bad argument')
        expect(=> @fixture.checkSpelling(47)).toThrow('Bad argument')

    describe '.getCorrectionsForMisspelling(word)', ->
      beforeEach ->
        @fixture = buildSpellChecker()
        @fixture.setDictionary defaultLanguage, dictionaryDirectory

      it 'returns an array of possible corrections', ->
        correction = ['word', 'world', 'word'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('worrd')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'throws an exception when no word specified', ->
        expect(-> @fixture.getCorrectionsForMisspelling()).toThrow()

      it 'returns an array of possible corrections for a correct English word', ->
        correction = ['cheese', 'chaise', 'cheesy'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('cheese')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for a correct Latin German word with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        correction = ['Acht', 'Macht', 'Acht'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('Nacht')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for a correct Latin German word with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        correction = ['Acht', 'Macht', 'Acht'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('Nacht')
        expect(corrections.length).toBeGreaterThan 0
        if spellType == "mac"
          # For some reason, the CI build will produce inconsistent results on
          # the Mac based on some external factor.
          expect(corrections[0] is 'Nicht' or corrections[0] is 'Macht').toEqual(true)
        else
          expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for a incorrect Latin German word with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        correction = ['Acht', 'Nicht', 'Acht'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('Nacht')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for a incorrect Latin German word with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        correction = ['Acht', 'SEE BELOW', 'Acht'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('Nacht')
        expect(corrections.length).toBeGreaterThan 0

        if spellType == "mac"
          # For some reason, the CI build will produce inconsistent results on
          # the Mac based on some external factor.
          expect(corrections[0] is 'Nicht' or corrections[0] is 'Macht').toEqual(true)
        else
          expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for correct Unicode German word with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        correction = ['vermöchten', 'vermochten', 'vermochte'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('vermöchten')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for correct Unicode German word with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        correction = ['vermöchten', 'vermochten', 'vermochte'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('vermöchten')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for incorrect Unicode German word with ISO8859-1 file', ->
        # de_DE_frami is invalid outside of Hunspell dictionaries.
        return unless spellType is 'hunspell'

        expect(@fixture.setDictionary('de_DE_frami', dictionaryDirectory)).toBe true
        correction = ['möchten', 'möchten', 'möchten'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('möchtzn')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for incorrect Unicode German word with UTF-8 file', ->
        expect(@fixture.setDictionary('de_DE', dictionaryDirectory)).toBe true
        correction = ['möchten', 'möchten', 'möchten'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('möchtzn')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for correct Unicode French word', ->
        expect(@fixture.setDictionary('fr', dictionaryDirectory)).toBe true
        correction = ['Françoise', 'Françoise', 'française'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('Française')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

      it 'returns an array of possible corrections for incorrect Unicode French word', ->
        expect(@fixture.setDictionary('fr', dictionaryDirectory)).toBe true
        correction = ['Françoise', 'Françoise', 'Françoise'][spellIndex]
        corrections = @fixture.getCorrectionsForMisspelling('Françoize')
        expect(corrections.length).toBeGreaterThan 0
        expect(corrections[0]).toEqual(correction)

    describe '.add(word) and .remove(word)', ->
      beforeEach ->
        @fixture = buildSpellChecker()
        @fixture.setDictionary defaultLanguage, dictionaryDirectory

      it 'allows words to be added and removed to the dictionary', ->
        # NB: Windows spellchecker cannot remove words, and since it holds onto
        # words, rerunning this test >1 time causes it to incorrectly fail
        return if process.platform is 'win32'

        expect(@fixture.isMisspelled('wwoorrdd')).toBe true

        @fixture.add('wwoorrdd')
        expect(@fixture.isMisspelled('wwoorrdd')).toBe false

        @fixture.remove('wwoorrdd')
        expect(@fixture.isMisspelled('wwoorrdd')).toBe true

      it 'add throws an error if no word is specified', ->
        errorOccurred = false
        try
          @fixture.add()
        catch
          errorOccurred = true
        expect(errorOccurred).toBe true

      it 'remove throws an error if no word is specified', ->
        errorOccurred = false
        try
          @fixture.remove()
        catch
          errorOccurred = true
        expect(errorOccurred).toBe true


    describe '.getAvailableDictionaries()', ->
      beforeEach ->
        @fixture = buildSpellChecker()
        @fixture.setDictionary defaultLanguage, dictionaryDirectory

      it 'returns an array of string dictionary names', ->
        # NB: getAvailableDictionaries is nop'ped in hunspell and it also doesn't
        # work inside Appveyor's CI environment
        return if spellType is 'hunspell' or process.env.CI

        dictionaries = @fixture.getAvailableDictionaries()
        expect(Array.isArray(dictionaries)).toBe true

        expect(dictionaries.length).toBeGreaterThan 0
        for dictionary in dictionaries.length
          expect(typeof dictionary).toBe 'string'
          expect(diction.length).toBeGreaterThan 0

    describe '.setDictionary(lang, dictDirectory)', ->
      it 'sets the spell checkers language, and dictionary directory', ->
        awesome = true
        expect(awesome).toBe true

  buildSpellChecker = ->
    checker = new Spellchecker()
    if testAlwaysUseHunspell
      checker.setSpellcheckerType(ALWAYS_USE_HUNSPELL)
      spellType = 'hunspell'
      spellIndex = 0
    else
      # We can get different results based on using Hunspell, Mac, or Windows
      # checkers. To simplify the rules, we create a variable that contains
      # 'hunspell', 'mac', or 'win' for filtering. We also create an index variable
      # to go into arrays.
      if process.env.SPELLCHECKER_PREFER_HUNSPELL
        spellType = 'hunspell'
        spellIndex = 0
      else if process.platform is 'darwin'
        spellType = 'mac'
        spellIndex = 1
      else if process.platform is 'win32'
        spellType = 'win'
        spellIndex = 2
      else
        spellType = 'hunspell'
        spellIndex = 0
    checker
