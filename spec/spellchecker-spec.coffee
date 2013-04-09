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
