SpellChecker = require '../lib/spellchecker'

describe "SpellChecker", ->
  describe ".isMisspelled(word)", ->
    it "returns true if the word is mispelled", ->
      expect(SpellChecker.isMisspelled('wwoorrdd')).toBe true

    it "returns false if the word isn't mispelled", ->
      expect(SpellChecker.isMisspelled('word')).toBe false

    it "throws an exception when no word specified", ->
      expect(-> SpellChecker.isMisspelled()).toThrow()

  describe ".getCorrectionsForMisspelling(word)", ->
    it "returns an array of possible corrections", ->
      corrections = SpellChecker.getCorrectionsForMisspelling('worrd')
      expect(corrections.length).toBeGreaterThan 0
      expect(corrections.indexOf('word')).toBeGreaterThan -1

    it "throws an exception when no word specified", ->
      expect(-> SpellChecker.getCorrectionsForMisspelling()).toThrow()

  describe ".getAvailableDictionaries()", ->
    it "returns an array of string dictionary names", ->
      dictionaries = SpellChecker.getAvailableDictionaries()
      expect(Array.isArray(dictionaries)).toBe true

      # Dictionaries do not appear to be available on AppVeyor
      unless process.platform is 'win32' and process.env.CI
        expect(dictionaries.length).toBeGreaterThan 0

      for dictionary in dictionaries.length
        expect(typeof dictionary).toBe 'string'
        expect(diction.length).toBeGreaterThan 0
