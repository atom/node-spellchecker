SpellChecker = require '../lib/spellchecker'

describe "SpellChecker", ->
  describe "isMisspelled(word)", ->
    it "returns true if the word is mispelled", ->
      expect(SpellChecker.isMisspelled('wwoorrdd')).toBe true

    it "returns false if the word isn't mispelled", ->
      expect(SpellChecker.isMisspelled('word')).toBe false

    it "throws an exception if no word specified", ->
      expect(-> SpellChecker.isMisspelled()).toThrow()
