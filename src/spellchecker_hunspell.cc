#include "spellchecker.h"

#include "../vendor/hunspell/src/hunspell/hunspell.hxx"

namespace spellchecker {

namespace {

Hunspell* g_hunspell = NULL;

}  // namespace

void Init(const std::string& dirname) {
  if (g_hunspell != NULL)
    return;

  std::string affixpath = dirname + "/../vendor/hunspell_dictionaries/en_US.aff";
  std::string dpath = dirname + "/../vendor/hunspell_dictionaries/en_US.dic";
  g_hunspell = new Hunspell(affixpath.c_str(), dpath.c_str());
}

bool IsMisspelled(const std::string& word) {
  return g_hunspell->spell(word.c_str()) == 0;
}

std::vector<std::string> GetCorrectionsForMisspelling(const std::string& word) {
  std::vector<std::string> corrections;
  char** slist;
  int size = g_hunspell->suggest(&slist, word.c_str());

  corrections.reserve(size);
  for (int i = 0; i < size; ++i)
    corrections.push_back(slist[i]);

  g_hunspell->free_list(&slist, size);
  return corrections;
}

}  // namespace spellchecker
