var path = require('path');
var bindings = require('../build/Release/spellchecker.node');

Spellchecker = bindings.Spellchecker;

var defaultSpellcheck = null;
var ensureDefaultSpellCheck = function() {
  if (defaultSpellcheck) return;

  defaultSpellcheck = new Spellchecker();
  defaultSpellcheck.setDictionary('en_US', path.join(__dirname, '..', 'vendor', 'hunspell_dictionaries'));
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
