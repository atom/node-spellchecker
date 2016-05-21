#include <cstdio>
#include <cwctype>
#include <algorithm>
#include "../vendor/hunspell/src/hunspell/hunspell.hxx"
#include "spellchecker_hunspell.h"

namespace spellchecker {

HunspellSpellchecker::HunspellSpellchecker() : transcoder(NewTranscoder()) { }

HunspellSpellchecker::~HunspellSpellchecker() {
  for (size_t i = 0; i < hunspells.size(); ++i) {
    delete hunspells[i].second;
  }

  if (transcoder) {
    FreeTranscoder(transcoder);
  }
}

bool HunspellSpellchecker::AddDictionary(const std::string& language, const std::string& dirname) {
  // NB: Hunspell uses underscore to separate language and locale, and Win8 uses
  // dash - if they use the wrong one, just silently replace it for them
  std::string lang = language;
  std::replace(lang.begin(), lang.end(), '-', '_');

  std::string affixpath = dirname + "/" + lang + ".aff";
  std::string dpath = dirname + "/" + lang + ".dic";

  // TODO: This code is almost certainly jacked on Win32 for non-ASCII paths
  FILE* handle = fopen(dpath.c_str(), "r");
  if (!handle) {
    return false;
  }
  fclose(handle);

  // TODO: On windows locale names are different
  std::locale loc(lang + ".UTF-8");
  Hunspell* hunspell = new Hunspell(affixpath.c_str(), dpath.c_str());
  hunspells.push_back(std::make_pair(loc, hunspell));
  return true;
}

bool HunspellSpellchecker::SetDictionary(const std::string& language, const std::string& dirname) {
  for (size_t i = 0; i < hunspells.size(); ++i) {
    delete hunspells[i].second;
  }
  hunspells.clear();

  return AddDictionary(language, dirname);
}

std::vector<std::string> HunspellSpellchecker::GetAvailableDictionaries(const std::string& path) {
  return std::vector<std::string>();
}

bool HunspellSpellchecker::IsMisspelled(const std::string& word) {
  for (size_t i = 0; i < hunspells.size(); ++i) {
    Hunspell* hunspell = hunspells[i].second;
    bool misspelled = hunspell->spell(word.c_str()) == 0;
    if (!misspelled) {
      return false;
    }
  }

  return true;
}

std::vector<MisspelledRange> HunspellSpellchecker::CheckSpelling(const uint16_t *utf16_text, size_t utf16_length) {
  std::vector<MisspelledRange> result;

  if (hunspells.empty() || !transcoder) {
    return result;
  }

  std::vector<char> utf8_buffer(256);

  enum {
    unknown,
    in_separator,
    in_word,
  } state = in_separator;

  for (size_t word_start = 0, i = 0; i < utf16_length; i++) {
    uint16_t c = utf16_text[i];

    switch (state) {
      case unknown:
        if (iswpunct(c) || iswspace(c)) {
          state = in_separator;
        }
        break;

      case in_separator:
        if (isAlpha(c)) {
          word_start = i;
          state = in_word;
        } else if (!iswpunct(c) && !iswspace(c)) {
          state = unknown;
        }
        break;

      case in_word:
        if (c == '\'' && isAlpha(utf16_text[i + 1])) {
          i++;
        } else if (c == 0 || iswpunct(c) || iswspace(c)) {
          state = in_separator;
          bool converted = TranscodeUTF16ToUTF8(transcoder, (char *)utf8_buffer.data(), utf8_buffer.size(), utf16_text + word_start, i - word_start);
          if (converted) {
            bool all_misspelled = true;
            for (size_t i = 0; i < hunspells.size(); ++i) {
              Hunspell* hunspell = hunspells[i].second;
              bool misspelled = hunspell->spell(utf8_buffer.data()) == 0;
              if (!misspelled) {
                all_misspelled = false;
                break;
              }
            }
            if (all_misspelled) {
              MisspelledRange range;
              range.start = word_start;
              range.end = i;
              result.push_back(range);
            }
          }
        } else if (!isAlpha(c)) {
          state = unknown;
        }
        break;
    }
  }

  return result;
}

void HunspellSpellchecker::Add(const std::string& word) {
  if (!hunspells.empty()) {
    Hunspell* hunspell = hunspells[0].second;
    hunspell->add(word.c_str());
  }
}

void HunspellSpellchecker::Remove(const std::string& word) {
  if (!hunspells.empty()) {
    Hunspell* hunspell = hunspells[0].second;
    hunspell->remove(word.c_str());
  }
}

std::vector<std::string> HunspellSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  std::vector<std::string> corrections;

  for (size_t i = 0; i < hunspells.size(); ++i) {
    Hunspell* hunspell = hunspells[i].second;

    char** slist;
    int size = hunspell->suggest(&slist, word.c_str());

    corrections.reserve(size);
    for (int i = 0; i < size; ++i) {
      corrections.push_back(slist[i]);
    }

    hunspell->free_list(&slist, size);
  }
  return corrections;
}

bool HunspellSpellchecker::isAlpha(std::wint_t c) const {
  if (iswalpha(c)) {
    return true;
  }
  for (size_t i = 0; i < hunspells.size(); ++i) {
    std::locale loc = hunspells[i].first;
    if (std::isalpha((wchar_t)c, loc)) {
      return true;
    }
  }
  return false;
}

}  // namespace spellchecker
