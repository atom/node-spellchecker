#include <cstdio>
#include "../vendor/hunspell/src/hunspell/hunspell.hxx"
#include "spellchecker_hunspell.h"

namespace spellchecker {

HunspellSpellchecker::HunspellSpellchecker() {
  this->hunspell = NULL;
}

HunspellSpellchecker::~HunspellSpellchecker() {
  if (!this->hunspell) return;

  delete this->hunspell;
}

bool HunspellSpellchecker::SetDictionary(const std::string& language, const std::string& dirname) {
  if (hunspell != NULL) {
    delete this->hunspell;
    hunspell = NULL;
  }

  std::string affixpath = dirname + "/" + language + ".aff";
  std::string dpath = dirname + "/" + language + ".dic";

  // TODO: This code is almost certainly jacked on Win32 for non-ASCII paths
  FILE* handle = fopen(dpath.c_str(), "r");
  if (!handle) {
    return false;
  }

  fclose(handle);
  this->hunspell = new Hunspell(affixpath.c_str(), dpath.c_str());
  return true;
}

std::vector<std::string> HunspellSpellchecker::GetAvailableDictionaries(const std::string& path) {
  return std::vector<std::string>();
}

bool HunspellSpellchecker::IsMisspelled(const std::string& word) {
  return this->hunspell->spell(word.c_str()) == 0;
}

std::vector<std::string> HunspellSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  std::vector<std::string> corrections;
  char** slist;
  int size = hunspell->suggest(&slist, word.c_str());

  corrections.reserve(size);
  for (int i = 0; i < size; ++i) {
    corrections.push_back(slist[i]);
  }

  this->hunspell->free_list(&slist, size);
  return corrections;
}

}  // namespace spellchecker
