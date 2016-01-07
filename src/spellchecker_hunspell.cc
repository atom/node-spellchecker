#include <cstdio>
#include <cwctype>
#include <algorithm>
#include "../vendor/hunspell/src/hunspell/hunspell.hxx"
#include "spellchecker_hunspell.h"

namespace spellchecker {

HunspellSpellchecker::HunspellSpellchecker() : hunspell(NULL), transcoder(NewTranscoder()) { }

HunspellSpellchecker::~HunspellSpellchecker() {
  if (hunspell) {
    delete hunspell;
  }

  if (transcoder) {
    FreeTranscoder(transcoder);
  }
}

bool HunspellSpellchecker::SetDictionary(const std::string& language, const std::string& dirname) {
  if (hunspell) {
    delete hunspell;
    hunspell = NULL;
  }

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

  hunspell = new Hunspell(affixpath.c_str(), dpath.c_str());
  return true;
}

std::vector<std::string> HunspellSpellchecker::GetAvailableDictionaries(const std::string& path) {
  return std::vector<std::string>();
}

bool HunspellSpellchecker::IsMisspelled(const std::string& word) {
  if (!hunspell) {
    return false;
  }
  return hunspell->spell(word.c_str()) == 0;
}

std::vector<MisspelledRange> HunspellSpellchecker::CheckSpelling(const uint16_t *utf16_text, size_t utf16_length) {
  std::vector<MisspelledRange> result;

  if (!hunspell || !transcoder) {
    return result;
  }

  std::vector<char> utf8_buffer(256);

  size_t word_start = 0;
  bool within_word = false;
  for (size_t i = 0; i < utf16_length; i++) {
    uint16_t c = utf16_text[i];
    bool is_word_character = iswalpha(c);
    if (within_word) {
      if (!is_word_character) {
        within_word = false;

        bool converted = TranscodeUTF16ToUTF8(transcoder, (char *)utf8_buffer.data(), utf8_buffer.size(), utf16_text + word_start, i - word_start);
        if (converted) {
          if (hunspell->spell(utf8_buffer.data()) == 0) {
            MisspelledRange range;
            range.start = word_start;
            range.end = i;
            result.push_back(range);
          }
        }
      }
    } else if (is_word_character) {
      word_start = i;
      within_word = true;
    }
  }

  return result;
}

void HunspellSpellchecker::Add(const std::string& word) {
  if (hunspell) {
    hunspell->add(word.c_str());
  }
}

std::vector<std::string> HunspellSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  std::vector<std::string> corrections;

  if (hunspell) {
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

}  // namespace spellchecker
