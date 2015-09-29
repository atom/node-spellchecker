SpellChecker = require '../lib/spellchecker'

describe "SpellChecker", ->

  describe "getDefaultLanguage()", ->
    it "uses the system default dictionary", ->
      systemDefaultLanguage = SpellChecker.getDefaultLanguage()
      systemDefaultLanguage = systemDefaultLanguage.toLowerCase().replace('-', '_')
      switch systemDefaultLanguage
        when "en_gb", "en_uk"
          expect(SpellChecker.isMisspelled('colour')).toBe false;
          expect(SpellChecker.isMisspelled('color')).toBe true;
        when "en", "en_us"
          expect(SpellChecker.isMisspelled('colour')).toBe true;
          expect(SpellChecker.isMisspelled('color')).toBe false;

  describe ".isMisspelled(word)", ->
    it "returns true if the word is mispelled", ->
      SpellChecker.setLanguage('en') # Override the system default.
      expect(SpellChecker.isMisspelled('wwoorrdd')).toBe true

    it "returns false if the word isn't mispelled", ->
      SpellChecker.setLanguage('en')
      expect(SpellChecker.isMisspelled('word')).toBe false

    it "throws an exception when no word specified", ->
      expect(-> SpellChecker.isMisspelled()).toThrow()

  describe ".getCorrectionsForMisspelling(word)", ->
    it "returns an array of possible corrections", ->
      SpellChecker.setLanguage('en')
      corrections = SpellChecker.getCorrectionsForMisspelling('worrd')
      expect(corrections.length).toBeGreaterThan 0
      expect(corrections.indexOf('word')).toBeGreaterThan -1

    it "throws an exception when no word specified", ->
      expect(-> SpellChecker.getCorrectionsForMisspelling()).toThrow()


    it "throws an error if no word is specified", ->
      errorOccurred = false
      try
        Spellchecker.add()
      catch
        errorOccurred = true
      expect(errorOccurred).toBe true

  describe ".getAvailableDictionaries()", ->
    it "returns an array of string dictionary names", ->
      dictionaries = SpellChecker.getAvailableDictionaries()
      expect(Array.isArray(dictionaries)).toBe true

      # Dictionaries do not appear to be available on AppVeyor
      unless process.platform is 'win32' and (process.env.CI or process.env.SPELLCHECKER_PREFER_HUNSPELL)
        expect(dictionaries.length).toBeGreaterThan 0

      for dictionary in dictionaries.length
        expect(typeof dictionary).toBe 'string'
        expect(diction.length).toBeGreaterThan 0

  describe ".setLanguage(lang, dictDirectory)", ->
    it "sets the spell checker's language", ->
      SpellChecker.setLanguage('de')
      expect(SpellChecker.isMisspelled('Wortwitz')).toBe false
      expect(SpellChecker.isMisspelled('Wortwitzz')).toBe true
      expect(SpellChecker.isMisspelled('Schnabeltier')).toBe false
      expect(SpellChecker.isMisspelled('Platypus')).toBe true
      SpellChecker.setLanguage('en_uk')
      expect(SpellChecker.isMisspelled('colour')).toBe false
      expect(SpellChecker.isMisspelled('color')).toBe true
      SpellChecker.setLanguage('en_us')
      expect(SpellChecker.isMisspelled('color')).toBe false
      expect(SpellChecker.isMisspelled('colour')).toBe true
