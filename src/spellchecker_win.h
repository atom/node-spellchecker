#ifndef SRC_SPELLCHECKER_WIN_H_
#define SRC_SPELLCHECKER_WIN_H_

#include <spellcheck.h>
#include "spellchecker.h"

namespace spellchecker {

class WindowsSpellchecker : public SpellcheckerImplementation {
public:
  bool IsSupported();

  WindowsSpellchecker();
  ~WindowsSpellchecker();

  bool SetDictionary(const std::string& language, const std::string& path);
  std::vector<std::string> GetAvailableDictionaries(const std::string& path);

  std::vector<std::string> GetCorrectionsForMisspelling(const std::string& word);
  bool IsMisspelled(const std::string& word);
  void Add(const std::string& word);

private:
  ISpellChecker* currentSpellchecker;
  ISpellCheckerFactory* spellcheckerFactory;
};

}  // namespace spellchecker

#endif  // SRC_SPELLCHECKER_MAC_H_
