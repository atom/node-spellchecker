var path = require('path');
var fs = require('fs');
var bindings = require('../build/Release/spellchecker.node');

var Spellchecker = bindings.Spellchecker;

var defaultSpellcheck = null;

var ensureDefaultSpellCheck = function() {
  if (defaultSpellcheck) {
    return;
  }

  var lang = process.env.LANG;
  lang = lang ? lang.split('.')[0] : 'en_US';
  defaultSpellcheck = new Spellchecker();

  setDictionary(lang, getDictionaryPath());
};

var setDictionary = function(lang, dictPath) {
  ensureDefaultSpellCheck();
  
  var filePath = path.join(dictPath, lang.replace(/_/g, '-') + '.bdic');
  var contents = null;
  try {
    contents = fs.readFileSync(filePath);
  } catch (e) {
    return false;
  }
  
  return defaultSpellcheck.setDictionary(lang, contents);
};

var isMisspelled = function() {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.isMisspelled.apply(defaultSpellcheck, arguments);
};

var checkSpelling = function() {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.checkSpelling.apply(defaultSpellcheck, arguments);
};

var add = function() {
  ensureDefaultSpellCheck();

  defaultSpellcheck.add.apply(defaultSpellcheck, arguments);
};

var remove = function() {
  ensureDefaultSpellCheck();

  defaultSpellcheck.remove.apply(defaultSpellcheck, arguments);
};

var getCorrectionsForMisspelling = function() {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.getCorrectionsForMisspelling.apply(defaultSpellcheck, arguments);
};

var getAvailableDictionaries = function() {
  ensureDefaultSpellCheck();

  return defaultSpellcheck.getAvailableDictionaries.apply(defaultSpellcheck, arguments);
};

var getDictionaryPath = function() {
  var dict = path.join(__dirname, '..', 'vendor', 'hunspell_dictionaries');
  return dict;
}

module.exports = {
  setDictionary: setDictionary,
  add: add,
  remove: remove,
  isMisspelled: isMisspelled,
  checkSpelling: checkSpelling,
  getAvailableDictionaries: getAvailableDictionaries,
  getCorrectionsForMisspelling: getCorrectionsForMisspelling,
  Spellchecker: Spellchecker
};
