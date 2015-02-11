#include "spellchecker.h"
#include "spellchecker_win.h"
#include "spellchecker_hunspell.h"

namespace spellchecker {

bool WindowsSpellchecker::IsSupported() {
  return false;
}

void WindowsSpellchecker::SetDictionary(const std::string& language, const std::string& path) {
}

bool WindowsSpellchecker::IsMisspelled(const std::string& word) {
  return false;
}

std::vector<std::string> WindowsSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  return std::vector<std::string>();
}

SpellcheckerImplementation* SpellcheckerFactory::CreateSpellchecker() {
  if (WindowsSpellchecker::IsSupported()) {
    return new WindowsSpellchecker();
  } else {
    return new HunspellSpellchecker();
  }
}

}  // namespace spellchecker
