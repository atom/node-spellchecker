#include <cstdio>
#include <cwctype>
#include <algorithm>
#include <fstream>
#include "../vendor/hunspell/src/hunspell/hunspell.hxx"
#include "spellchecker_hunspell.h"

#ifdef WIN32

#define SEARCH_PATHS "C:\\Hunspell\\"
#define DIR_SEPARATOR "\\"
#define PATH_SEPARATOR ";"

#else

// Not windows
#include <sys/types.h>
#include <dirent.h>

#define SEARCH_PATHS \
  "/usr/share/hunspell:" \
  "/usr/share/myspell:" \
  "/usr/share/myspell/dicts:" \
  "/Library/Spelling"
#define DIR_SEPARATOR "/"
#define PATH_SEPARATOR ":"

#endif

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

  std::string search_path = dirname + PATH_SEPARATOR + SEARCH_PATHS;

  std::string affixpath = FindDictionary(search_path, lang, ".aff");
  std::string dpath = FindDictionary(search_path, lang, ".dic");

  if (dpath.compare("") == 0) {
    return false;
  }

  hunspell = new Hunspell(affixpath.c_str(), dpath.c_str());
  return true;
}

std::vector<std::string> HunspellSpellchecker::GetAvailableDictionaries(const std::string& path) {
  std::string search_path = path + PATH_SEPARATOR + SEARCH_PATHS;

  return SearchAvailableDictionaries(search_path);
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
        if (iswalpha(c)) {
          word_start = i;
          state = in_word;
        } else if (!iswpunct(c) && !iswspace(c)) {
          state = unknown;
        }
        break;

      case in_word:
        if (c == '\'' && iswalpha(utf16_text[i + 1])) {
          i++;
        } else if (c == 0 || iswpunct(c) || iswspace(c)) {
          state = in_separator;
          bool converted = TranscodeUTF16ToUTF8(transcoder, (char *)utf8_buffer.data(), utf8_buffer.size(), utf16_text + word_start, i - word_start);
          if (converted) {
            if (hunspell->spell(utf8_buffer.data()) == 0) {
              MisspelledRange range;
              range.start = word_start;
              range.end = i;
              result.push_back(range);
            }
          }
        } else if (!iswalpha(c)) {
          state = unknown;
        }
        break;
    }
  }

  return result;
}

void HunspellSpellchecker::Add(const std::string& word) {
  if (hunspell) {
    hunspell->add(word.c_str());
  }
}

void HunspellSpellchecker::Remove(const std::string& word) {
  if (hunspell) {
    hunspell->remove(word.c_str());
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

std::vector<std::string> HunspellSpellchecker::SearchAvailableDictionaries(const std::string& path) {
  const char * c_path = path.c_str();
  char * begin = const_cast<char *>(c_path); // TODO: Do we need this?
  char * end = begin;

  std::vector<std::string> my_list;

  while (1) {
    while ( ! ((*end == *PATH_SEPARATOR) || (*end == '\0'))) {
      end++;
    }

    std::string search_path;
    search_path.assign(begin, end - begin);
    search_path.append(DIR_SEPARATOR);

#ifdef WIN32
    // TODO: Windows compatibility?
#else
    DIR* dir = opendir(search_path.c_str());

    if (dir) {
      struct dirent* de;
      while ((de = readdir(dir))) {
        std::string filename(de->d_name);

        if (filename.size() > 4 && filename.compare(filename.size() - 4, 4, ".dic") == 0) {
          my_list.push_back(filename.substr(0, filename.size() - 4));
        }
        else if (filename.size() > 7 && filename.compare(filename.size() - 7, 7, ".dic.hz") == 0) {
          my_list.push_back(filename.substr(0, filename.size() - 7));
        }
      }

      closedir(dir);
    }
#endif

    if (*end == '\0') {
      return my_list;
    }

    end++;
    begin = end;
  }
}

std::string HunspellSpellchecker::FindDictionary(const std::string& path, const std::string& language, const std::string& extension) {
  const char * c_path = path.c_str();
  char * begin = const_cast<char *>(c_path); // TODO: Do we need this?
  char * end = begin;

  while (1) {
    while ( ! ((*end == *PATH_SEPARATOR) || (*end == '\0'))) {
      end++;
    }

    std::string file_path;
    file_path.assign(begin, end - begin);
    file_path.append(DIR_SEPARATOR);
    file_path.append(language);
    file_path.append(extension);

    std::ifstream f;
    f.open(file_path, std::ios_base::in);
    if (f.is_open()) {
      return file_path;
    }

    file_path.append(".hz");

    f.open(file_path, std::ios_base::in);
    if (f.is_open()) {
      return file_path;
    }

    if (*end == '\0') {
      return "";
    }

    end++;
    begin = end;
  }
}

}  // namespace spellchecker
