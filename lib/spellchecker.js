var path = require("path");
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
  this.userDictPath = null;
};

SpellcheckerFactory.prototype.clearCache = function(){
  var emptyKeys = [];
  this.cache.forEach(function(v, k){
    if(!v) emptyKeys.push(k);
  });
  emptyKeys.forEach(function(k){
    this.cache.delete(k);
  }, this)
}

SpellcheckerFactory.prototype.getSpellChecker = function(lang){
  var spellchecker = this.cache.get(lang);
  if(this.cache.has(lang)) {
    return spellchecker;
  }
  spellchecker = new Spellchecker();
  var success = spellchecker.setDictionary(lang, this.userDictPath || this.dictPath);
  if(!success && !spellchecker.isHunspell()) {
    spellchecker = new Spellchecker(true);
    success = spellchecker.setDictionary(lang, this.userDictPath || this.dictPath);
  }
  spellchecker = success ? spellchecker : null;
  this.cache.set(lang, spellchecker);
  if(spellchecker) {
    spellchecker.lang = lang;
  }
  return spellchecker;
}

SpellcheckerFactory.prototype.getUserDictionaryPath = function(){
  return this.userDictPath;
}

SpellcheckerFactory.prototype.setUserDictionaryPath = function(userDictPath){
  return this.userDictPath = userDictPath;
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
    try {
      require('cld').detect(text, options, function(err, result) {
        if(!result) return resolve(null, err);
  
        if (!result.reliable || result.languages[0].percent < 85) {
          return resolve(null, "No reliable result for lang check");
        }
  
        resolve(result.languages[0].code, null);
      });
    } catch(e) {
      resolve(null, e);
    }
  });
};

SpellcheckerFactory.prototype.Spellchecker = Spellchecker;

module.exports = new SpellcheckerFactory();
