var path = require('path');
var loophole = require('loophole');
var bindings = require('bindings')('spellchecker.node');

var Spellchecker = bindings.Spellchecker;

var defaultSpellcheck = null;

var objc, pool;

// Workaround NSSpellChecker bug
// http://stackoverflow.com/a/31383060
loophole.allowUnsafeNewFunction(function () {
  try {
    objc = require('nodobjc')
    objc.import('Cocoa');
    pool = objc.NSAutoreleasePool('alloc')('init');
    objc.NSApplication('sharedApplication');
    pool('release');
  } catch (ex) {}
});

var setDictionary = function(lang, dictPath) {
  defaultSpellcheck = new Spellchecker();
  // NB: Windows 8 uses *dashes* to set the language (i.e. en-US), so if we fail
  // to set the language, try the Windows 8 way
  lang = lang.replace('_', '-');
  if (!defaultSpellcheck.setDictionary(lang, dictPath)) {
    lang = lang.replace('-', '_');
    defaultSpellcheck.setDictionary(lang, dictPath);
  }
};

var ensureDefaultSpellCheck = function() {
  if (defaultSpellcheck) {
    return;
  }

  var lang = process.env.LANG;
  lang = lang ? lang.split('.')[0] : 'en_US';
  setDictionary(lang, getDictionaryPath());
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
  try {
    // HACK: Special case being in an asar archive
    var unpacked = dict.replace('.asar' + path.sep, '.asar.unpacked' + path.sep);
    if (require('fs').statSyncNoException(unpacked)) {
      dict = unpacked;
    }
  } catch (error) {
  }
  return dict;
}

module.exports = {
  setDictionary: setDictionary,
  add: add,
  isMisspelled: isMisspelled,
  checkSpelling: checkSpelling,
  getAvailableDictionaries: getAvailableDictionaries,
  getCorrectionsForMisspelling: getCorrectionsForMisspelling,
  Spellchecker: Spellchecker
};
