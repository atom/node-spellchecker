var path = require('path');
var bindings = require('../build/Release/spellchecker.node');

Spellchecker = bindings.Spellchecker;

var defaultSpellcheck = null;
var ensureDefaultSpellCheck = function() {
  if (defaultSpellcheck) return;

  defaultSpellcheck = new Spellchecker();
  defaultSpellcheck.setDictionary('en_US', path.join(__dirname, '..', 'vendor', 'hunspell_dictionaries'));
};

var isMisspelled = function(word) {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.isMisspelled(word);
};

var getCorrectionsForMisspelling = function(word) {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.getCorrectionsForMisspelling(word);
};

module.exports = {
  isMisspelled: isMisspelled,
  getCorrectionsForMisspelling: getCorrectionsForMisspelling,
  Spellchecker: Spellchecker
};
