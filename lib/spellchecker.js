var bindings = require('../build/Release/spellchecker.node');
bindings.init(__dirname);

module.exports = {
  isMisspelled: bindings.isMisspelled,
  getCorrectionsForMisspelling: bindings.getCorrectionsForMisspelling
};
