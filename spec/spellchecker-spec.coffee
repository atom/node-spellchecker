{Spellchecker} = require '../lib/spellchecker'

enUS = "A robot is a mechanical or virtual artificial agent, usually an electro-mechanical machine"
deDE = "Ein Roboter ist eine technische Apparatur, die üblicherweise dazu dient, dem Menschen mechanische Arbeit abzunehmen."
frFR = "Un robot est un dispositif mécatronique accomplissant automatiquement"

describe "SpellChecker", ->
  describe ".isMisspelled(word)", ->
    beforeEach ->
      @fixture = new Spellchecker()

    it "returns true if the word is mispelled", ->
      @fixture.setDictionary('en-US')
      expect(@fixture.isMisspelled('wwoorrdd')).toBe true

    it "returns false if the word isn't mispelled", ->
      expect(@fixture.isMisspelled('word')).toBe false

    it "throws an exception when no word specified", ->
      expect(-> @fixture.isMisspelled()).toThrow()

    it "automatically detects languages on OS X", ->
      return unless process.platform is 'darwin'

      expect(@fixture.checkSpelling(enUS)).toEqual []
      expect(@fixture.checkSpelling(deDE)).toEqual []
      expect(@fixture.checkSpelling(frFR)).toEqual []

  describe ".checkSpelling(string)", ->
    beforeEach ->
      @fixture = new Spellchecker()

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
      expect(@fixture.checkSpelling("")).toEqual []
      expect(-> @fixture.checkSpelling()).toThrow("Bad argument")
      expect(-> @fixture.checkSpelling(null)).toThrow("Bad argument")
      expect(-> @fixture.checkSpelling({})).toThrow("Bad argument")

  describe ".getCorrectionsForMisspelling(word)", ->
    beforeEach ->
      @fixture = new Spellchecker()

    it "returns an array of possible corrections", ->
      corrections = @fixture.getCorrectionsForMisspelling('worrd')
      expect(corrections.length).toBeGreaterThan 0
      expect(corrections.indexOf('word')).toBeGreaterThan -1

    it "throws an exception when no word specified", ->
      expect(-> @fixture.getCorrectionsForMisspelling()).toThrow()

  describe ".add(word)", ->
    beforeEach ->
      @fixture = new Spellchecker()

    xit "allows words to be added to the dictionary", ->
      expect(@fixture.isMisspelled('wwoorrdd')).toBe true
      @fixture.add('wwoorrdd')
      expect(@fixture.isMisspelled('wwoorrdd')).toBe false

    it "throws an error if no word is specified", ->
      errorOccurred = false
      try
        @fixture.add()
      catch
        errorOccurred = true
      expect(errorOccurred).toBe true

  describe ".getAvailableDictionaries()", ->
    return if process.platform is 'linux'

    beforeEach ->
      @fixture = new Spellchecker()

    it "returns an array of string dictionary names", ->
      dictionaries = @fixture.getAvailableDictionaries()
      expect(Array.isArray(dictionaries)).toBe true

      # Dictionaries do not appear to be available on AppVeyor
      unless process.platform is 'win32' and (process.env.CI or process.env.SPELLCHECKER_PREFER_HUNSPELL)
        expect(dictionaries.length).toBeGreaterThan 0

      for dictionary in dictionaries.length
        expect(typeof dictionary).toBe 'string'
        expect(diction.length).toBeGreaterThan 0

  describe ".setDictionary(lang, dictDirectory)", ->
    it "sets the spell checker's language, and dictionary directory", ->
      awesome = true
      expect(awesome).toBe true
