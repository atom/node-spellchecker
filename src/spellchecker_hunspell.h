#ifndef SRC_SPELLCHECKER_HUNSPELL_H_
#define SRC_SPELLCHECKER_HUNSPELL_H_

#include "spellchecker.h"

class Hunspell;

namespace spellchecker {

class HunspellSpellchecker : public SpellcheckerImplementation {
public:
  HunspellSpellchecker();
  ~HunspellSpellchecker();

  bool SetDictionary(const std::string& language, const std::string& path);
  std::vector<std::string> GetAvailableDictionaries(const std::string& path);
  std::vector<std::string> GetCorrectionsForMisspelling(const std::string& word);
  bool IsMisspelled(const std::string& word);
  void Add(const std::string& word);

private:
  Hunspell* hunspell;
};

}  // namespace spellchecker

#endif  // SRC_SPELLCHECKER_MAC_H_
