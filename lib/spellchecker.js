var bindings = require('bindings')('spellchecker.node');
bindings.init(__dirname);

module.exports = {
  isMisspelled: bindings.isMisspelled,
  getCorrectionsForMisspelling: bindings.getCorrectionsForMisspelling
};
