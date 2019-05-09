var path = require('path');
var fs = require('fs');
var bindings = require('../build/Release/spellchecker.node');

var Spellchecker = bindings.Spellchecker;

var defaultSpellcheck = null;
var dictionaryBaseURL = "https://redirector.gvt1.com/edgedl/chrome/dict/";

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

var setBaseUrlForHunspellDictionary = function(url) {
  if(url && url.length > 0){
    dictionaryBaseURL = url
  }
}

var getURLForHunspellDictionary = function(lang) {
  // NB: This is derived from https://code.google.com/p/chromium/codesearch#chromium/src/chrome/common/spellcheck_common.cc&sq=package:chromium&type=cs&rcl=1464736770&l=107
  var defaultVersion = '-3-0';
  var specialVersions = {
    'tr-tr': '-4-0',
    'tg-tg': '-5-0',
    'en-ca': '-8-0',
    'en-gb': '-8-0',
    'en-us': '-8-0',
    'fa-ir': '-8-0',
  };

  var nonFormedLangCode = ['ko', 'sh', 'sq', 'sr'];
  var langCode = lang.replace(/_/g, '-').toLowerCase();

  //some bdict in choromium does not follow form of language code with locale,
  //formed as language only (i.e, https://src.chromium.org/viewvc/chrome/trunk/deps/third_party/hunspell_dictionaries/ko-3-0.bdic)
  var language = langCode.split('-')[0];
  for (var idx = 0; idx < nonFormedLangCode.length; idx++) {
    if (language === nonFormedLangCode[idx]) {
      langCode = nonFormedLangCode[idx];
    }
  }

  return dictionaryBaseURL + langCode + (specialVersions[langCode] || defaultVersion) + ".bdic";
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
  setBaseUrlForHunspellDictionary: setBaseUrlForHunspellDictionary,
  Spellchecker: Spellchecker
};
