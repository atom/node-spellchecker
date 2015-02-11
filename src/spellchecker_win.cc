#include <windows.h>

#include "spellchecker.h"
#include "spellchecker_win.h"
#include "spellchecker_hunspell.h"

namespace spellchecker {

LONG g_COMRefcount = 0;
bool g_COMFailed = false;

WindowsSpellchecker::WindowsSpellchecker() {
  if (InterlockedIncrement(&g_COMRefcount) == 1) {
    g_COMFailed = FAILED(CoInitialize(NULL));
  }
}

WindowsSpellchecker::~WindowsSpellchecker() {
  if (InterlockedDecrement(&g_COMRefcount) == 0) {
    CoUninitialize();
  }
}

bool WindowsSpellchecker::IsSupported() {
  return g_COMFailed && false;
}

bool WindowsSpellchecker::SetDictionary(const std::string& language, const std::string& path) {
  return false;
}

bool WindowsSpellchecker::IsMisspelled(const std::string& word) {
  return false;
}

std::vector<std::string> WindowsSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  return std::vector<std::string>();
}

SpellcheckerImplementation* SpellcheckerFactory::CreateSpellchecker() {
  WindowsSpellchecker* ret = new WindowsSpellchecker();
  if (ret->IsSupported()) {
    return ret;
  }

  delete ret;
  return new HunspellSpellchecker();
}

}  // namespace spellchecker
