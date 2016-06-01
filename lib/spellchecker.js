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

var getURLForHunspellDictionary = function(lang) {
  // NB: This is derived from https://code.google.com/p/chromium/codesearch#chromium/src/chrome/common/spellcheck_common.cc&sq=package:chromium&type=cs&rcl=1464736770&l=107
  var defaultVersion = '-3-0';
  var specialVersions = {
    'tr-tr': '-4-0',
    'tg-tg': '-5-0',
    'en-ca': '-7-1',
    'en-gb': '-7-1',
    'en-us': '-7-1',
    'fa-ir': '-7-0',
  };
  
  var langCode = lang.replace(/_/g, '-').toLowerCase();
  return "https://redirector.gvt1.com/edgedl/chrome/dict/" + langCode + (specialVersions[lang] || defaultVersion) + ".bdic";
}

module.exports = {
  setDictionary: setDictionary,
  add: add,
  remove: remove,
  isMisspelled: isMisspelled,
  checkSpelling: checkSpelling,
  getAvailableDictionaries: getAvailableDictionaries,
  getCorrectionsForMisspelling: getCorrectionsForMisspelling,
  getURLForHunspellDictionary: getURLForHunspellDictionary,
  Spellchecker: Spellchecker
};
