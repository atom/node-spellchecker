var path = require("path");
var Promise = require("any-promise");
var bindings = require("../build/Release/spellchecker.node");

var Spellchecker = bindings.Spellchecker;

var checkSpellingAsyncCb = Spellchecker.prototype.checkSpellingAsync;

Spellchecker.prototype.checkSpellingAsync = function(corpus) {
  return new Promise(
    function(resolve, reject) {
      checkSpellingAsyncCb.call(this, corpus, function(err, result) {
        if (err) {
          reject(err);
        } else {
          resolve(result);
        }
      });
    }.bind(this)
  );
};

var SpellcheckerFactory = function() {
  this.cache = new Map();
  this.dictPath = this.getDictionaryPath();
};

SpellcheckerFactory.prototype.getSpellChecker = function(lang){
  var spellchecker = this.cache.get(lang);
  if(this.cache.has(lang)) {
    return spellchecker;
  }
  spellchecker = new Spellchecker();
  var success = spellchecker.setDictionary(lang, this.dictPath);
  if(!success && !spellchecker.isHunspell()) {
    spellchecker = new Spellchecker(true);
    success = spellchecker.setDictionary(lang, this.dictPath);
  }
  spellchecker = success ? spellchecker : null;
  this.cache.set(lang, spellchecker);
  return spellchecker;
}

SpellcheckerFactory.prototype.getDictionaryPath = function() {
  var dict = path.join(__dirname, "..", "vendor", "hunspell_dictionaries");
  try {
    // HACK: Special case being in an asar archive
    var unpacked = dict.replace(
      ".asar" + path.sep,
      ".asar.unpacked" + path.sep
    );
    if (require("fs").statSyncNoException(unpacked)) {
      dict = unpacked;
    }
  } catch (error) {}
  return dict;
};

SpellcheckerFactory.prototype.detectLanguageForText = function(text, options){
  return new Promise(function(resolve){
    require('cld').detect(text, options, function(err, result) {
      if(!result) return resolve(null);

      if (!result.reliable || result.languages[0].percent < 85) {
        return resolve(null);
      }

      resolve(result.languages[0].code);
    });
  });
};

SpellcheckerFactory.prototype.Spellchecker = Spellchecker;

module.exports = new SpellcheckerFactory();
