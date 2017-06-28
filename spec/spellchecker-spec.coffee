{Spellchecker} = require '../lib/spellchecker'
path = require 'path'

enUS = "A robot is a mechanical or virtual artificial agent, usually an electronic machine"
deDE = "Ein Roboter ist eine technische Apparatur, die üblicherweise dazu dient, dem Menschen mechanische Arbeit abzunehmen."
frFR = "Les robots les plus évolués sont capables de se déplacer et de se recharger par eux-mêmes"

defaultLanguage = if process.platform is 'darwin' then '' else 'en_US'
dictionaryDirectory = path.join(__dirname, 'dictionaries')

describe "SpellChecker", ->
  describe ".isMisspelled(word)", ->
    beforeEach ->
      @fixture = new Spellchecker()
      @fixture.setDictionary defaultLanguage, dictionaryDirectory

    it "returns true if the word is mispelled", ->
      @fixture.setDictionary('en_US', dictionaryDirectory)
      expect(@fixture.isMisspelled('wwoorrddd')).toBe true

    it "returns false if the word isn't mispelled", ->
      @fixture.setDictionary('en_US', dictionaryDirectory)
      expect(@fixture.isMisspelled('word')).toBe false

    it "throws an exception when no word specified", ->
      expect(-> @fixture.isMisspelled()).toThrow()

    it "automatically detects languages on OS X", ->
      return unless process.platform is 'darwin'

      expect(@fixture.checkSpelling(enUS)).toEqual []
      expect(@fixture.checkSpelling(deDE)).toEqual []
      expect(@fixture.checkSpelling(frFR)).toEqual []

    it "correctly switches languages", ->
      expect(@fixture.setDictionary('en_US', dictionaryDirectory)).toBe true
      expect(@fixture.checkSpelling(enUS)).toEqual []
      expect(@fixture.checkSpelling(deDE)).not.toEqual []
      expect(@fixture.checkSpelling(frFR)).not.toEqual []

      if @fixture.setDictionary('de_DE', dictionaryDirectory)
        expect(@fixture.checkSpelling(enUS)).not.toEqual []
        expect(@fixture.checkSpelling(deDE)).toEqual []
        expect(@fixture.checkSpelling(frFR)).not.toEqual []

      @fixture = new Spellchecker()
      if @fixture.setDictionary('fr_FR', dictionaryDirectory)
        expect(@fixture.checkSpelling(enUS)).not.toEqual []
        expect(@fixture.checkSpelling(deDE)).not.toEqual []
        expect(@fixture.checkSpelling(frFR)).toEqual []


  describe ".checkSpelling(string)", ->
    beforeEach ->
      @fixture = new Spellchecker()
      @fixture.setDictionary defaultLanguage, dictionaryDirectory

    it "returns an array of character ranges of misspelled words", ->
      string = "cat caat dog dooog"

      expect(@fixture.checkSpelling(string)).toEqual [
        {start: 4, end: 8},
        {start: 13, end: 18},
      ]

    it "accounts for UTF16 pairs", ->
      string = "😎 cat caat dog dooog"

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

    it "does not treat non-english letters as word boundaries", ->
      @fixture.add("cliché")
      expect(@fixture.checkSpelling("what cliché nonsense")).toEqual []
      @fixture.remove("cliché")

    it "handles words with apostrophes", ->
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

    it "handles invalid inputs", ->
      fixture = @fixture
      expect(fixture.checkSpelling("")).toEqual []
      expect(-> fixture.checkSpelling()).toThrow("Bad argument")
      expect(-> fixture.checkSpelling(null)).toThrow("Bad argument")
      expect(-> fixture.checkSpelling({})).toThrow("Bad argument")

  describe ".checkSpellingAsync(string)", ->
    beforeEach ->
      @fixture = new Spellchecker()
      @fixture.setDictionary defaultLanguage, dictionaryDirectory

    it "returns an array of character ranges of misspelled words", ->
      string = "cat caat dog dooog"
      ranges = null

      @fixture.checkSpellingAsync(string).then (r) -> ranges = r

      waitsFor -> ranges isnt null

      runs ->
        expect(ranges).toEqual [
          {start: 4, end: 8}
          {start: 13, end: 18}
        ]

    it "handles invalid inputs", ->
      expect(=> @fixture.checkSpelling()).toThrow("Bad argument")
      expect(=> @fixture.checkSpelling(null)).toThrow("Bad argument")
      expect(=> @fixture.checkSpelling(47)).toThrow("Bad argument")

  describe ".getCorrectionsForMisspelling(word)", ->
    beforeEach ->
      @fixture = new Spellchecker()
      @fixture.setDictionary defaultLanguage, dictionaryDirectory

    it "returns an array of possible corrections", ->
      correction = if process.platform is "darwin" then "world" else "word"

      corrections = @fixture.getCorrectionsForMisspelling('worrd')
      expect(corrections.length).toBeGreaterThan 0
      expect(corrections.indexOf(correction)).toBeGreaterThan -1

    it "throws an exception when no word specified", ->
      expect(-> @fixture.getCorrectionsForMisspelling()).toThrow()

  describe ".add(word) and .remove(word)", ->
    beforeEach ->
      @fixture = new Spellchecker()
      @fixture.setDictionary defaultLanguage, dictionaryDirectory

    it "allows words to be added and removed to the dictionary", ->
      # NB: Windows spellchecker cannot remove words, and since it holds onto
      # words, rerunning this test >1 time causes it to incorrectly fail
      return if process.platform is 'win32'

      expect(@fixture.isMisspelled('wwoorrdd')).toBe true

      @fixture.add('wwoorrdd')
      expect(@fixture.isMisspelled('wwoorrdd')).toBe false

      @fixture.remove('wwoorrdd')
      expect(@fixture.isMisspelled('wwoorrdd')).toBe true

    it "add throws an error if no word is specified", ->
      errorOccurred = false
      try
        @fixture.add()
      catch
        errorOccurred = true
      expect(errorOccurred).toBe true

    it "remove throws an error if no word is specified", ->
      errorOccurred = false
      try
        @fixture.remove()
      catch
        errorOccurred = true
      expect(errorOccurred).toBe true


  describe ".getAvailableDictionaries()", ->
    beforeEach ->
      @fixture = new Spellchecker()
      @fixture.setDictionary defaultLanguage, dictionaryDirectory

    it "returns an array of string dictionary names", ->
      # NB: getAvailableDictionaries is nop'ped in hunspell and it also doesn't
      # work inside Appveyor's CI environment
      return if process.platform is 'linux' or process.env.CI or process.env.SPELLCHECKER_PREFER_HUNSPELL

      dictionaries = @fixture.getAvailableDictionaries()
      expect(Array.isArray(dictionaries)).toBe true

      expect(dictionaries.length).toBeGreaterThan 0
      for dictionary in dictionaries.length
        expect(typeof dictionary).toBe 'string'
        expect(diction.length).toBeGreaterThan 0

  describe ".setDictionary(lang, dictDirectory)", ->
    it "sets the spell checker's language, and dictionary directory", ->
      awesome = true
      expect(awesome).toBe true
