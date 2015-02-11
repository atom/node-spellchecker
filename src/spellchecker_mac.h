#ifndef SRC_SPELLCHECKER_MAC_H_
#define SRC_SPELLCHECKER_MAC_H_

#include "spellchecker.h"

namespace spellchecker {

class MacSpellchecker : public SpellcheckerImplementation {
public:
  bool SetDictionary(const std::string& language, const std::string& path);
  std::vector<std::string> GetCorrectionsForMisspelling(const std::string& word);
  bool IsMisspelled(const std::string& word);
};

}  // namespace spellchecker

#endif  // SRC_SPELLCHECKER_MAC_H_
