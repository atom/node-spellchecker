var path = require('path');
var bindings = require('../build/Release/spellchecker.node');

Spellchecker = bindings.Spellchecker;

var defaultSpellcheck = null;
var ensureDefaultSpellCheck = function() {
  if (defaultSpellcheck) return;

  defaultSpellcheck = new Spellchecker();

  // NB: Windows 8 uses *dashes* to set the language (i.e. en-US), so if we fail
  // to set the language, try the Windows 8 way
  var dict = path.join(__dirname, '..', 'vendor', 'hunspell_dictionaries');
  if (!defaultSpellcheck.setDictionary('en_US', dict)) {
    defaultSpellcheck.setDictionary('en-US', dict);
  }
};

var isMisspelled = function() {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.isMisspelled.apply(defaultSpellcheck, arguments);
};

var getCorrectionsForMisspelling = function() {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.getCorrectionsForMisspelling.apply(defaultSpellcheck, arguments);
};

var getAvailableDictionaries = function() {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.getAvailableDictionaries.apply(defaultSpellcheck, arguments);
};

module.exports = {
  isMisspelled: isMisspelled,
  getAvailableDictionaries: getAvailableDictionaries,
  getCorrectionsForMisspelling: getCorrectionsForMisspelling,
  Spellchecker: Spellchecker
};
