#ifndef SRC_SPELLCHECKER_H_
#define SRC_SPELLCHECKER_H_

#include <string>
#include <vector>

namespace spellchecker {

class SpellcheckerImplementation {
public:
  virtual void SetDictionary(const std::string& language, const std::string& path) = 0;

  // Returns an array containing possible corrections for the word.
  virtual std::vector<std::string> GetCorrectionsForMisspelling(const std::string& word) = 0;

  // Returns true if the word is misspelled.
  virtual bool IsMisspelled(const std::string& word) = 0;

  virtual ~SpellcheckerImplementation() {}
};

}  // namespace spellchecker

#endif  // SRC_SPELLCHECKER_H_
