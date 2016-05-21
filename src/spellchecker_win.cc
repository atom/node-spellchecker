#include <windows.h>
#include <guiddef.h>
#include <initguid.h>
#include <string>
#include <algorithm>
#include <cstdlib>
#include <spellcheck.h>

#include "spellchecker.h"
#include "spellchecker_win.h"
#include "spellchecker_hunspell.h"

// NB: No idea why I have to define this myself, you don't have to in a
// standard console app.
DEFINE_GUID(CLSID_SpellCheckerFactory,0x7AB36653,0x1796,0x484B,0xBD,0xFA,0xE7,0x4F,0x1D,0xB7,0xC1,0xDC);
DEFINE_GUID(IID_ISpellCheckerFactory,0x8E018A9D,0x2415,0x4677,0xBF,0x08,0x79,0x4E,0xA6,0x1F,0x94,0xBB);

namespace spellchecker {

LONG g_COMRefcount = 0;
bool g_COMFailed = false;

static bool compareMisspelledRanges(const MisspelledRange& lhs, const MisspelledRange& rhs) {
  return lhs.start < rhs.start;
}

std::string ToUTF8(const std::wstring& string) {
  if (string.length() < 1) {
    return std::string();
  }

  // NB: In the pathological case, each character could expand up
  // to 4 bytes in UTF8.
  int cbLen = (string.length()+1) * sizeof(char) * 4;
  char* buf = new char[cbLen];
  int retLen = WideCharToMultiByte(CP_UTF8, 0, string.c_str(), string.length(), buf, cbLen, NULL, NULL);
  buf[retLen] = 0;

  std::string ret;
  ret.assign(buf);
  return ret;
}

std::wstring ToWString(const std::string& string) {
  if (string.length() < 1) {
    return std::wstring();
  }

  // NB: If you got really unlucky, every character could be a two-wchar_t
  // surrogate pair
  int cchLen = (string.length()+1) * 2;
  wchar_t* buf = new wchar_t[cchLen];
  int retLen = MultiByteToWideChar(CP_UTF8, 0, string.c_str(), strlen(string.c_str()), buf, cchLen);
  buf[retLen] = 0;

  std::wstring ret;
  ret.assign(buf);
  return ret;
}

WindowsSpellchecker::WindowsSpellchecker() {
  this->spellcheckerFactory = NULL;

  if (InterlockedIncrement(&g_COMRefcount) == 1) {
    g_COMFailed = FAILED(CoInitialize(NULL));
    if (g_COMFailed) return;
  }

  // NB: This will fail on < Win8
  HRESULT hr = CoCreateInstance(
    CLSID_SpellCheckerFactory, NULL, CLSCTX_INPROC_SERVER, IID_ISpellCheckerFactory,
    reinterpret_cast<PVOID*>(&this->spellcheckerFactory));

  if (FAILED(hr)) {
    this->spellcheckerFactory = NULL;
  }
}

WindowsSpellchecker::~WindowsSpellchecker() {
  for (size_t i = 0; i < this->currentSpellcheckers.size(); ++i) {
    ISpellChecker* currentSpellchecker = this->currentSpellcheckers[i];
    currentSpellchecker->Release();
  }
  this->currentSpellcheckers.clear();

  if (this->spellcheckerFactory) {
    this->spellcheckerFactory->Release();
    this->spellcheckerFactory = NULL;
  }

  if (InterlockedDecrement(&g_COMRefcount) == 0) {
    CoUninitialize();
  }
}

bool WindowsSpellchecker::IsSupported() {
  return !(g_COMFailed || (this->spellcheckerFactory == NULL));
}

bool WindowsSpellchecker::AddDictionary(const std::string& language, const std::string& path) {
  if (!this->spellcheckerFactory) {
    return false;
  }

  // Figure out if we have a dictionary installed for the language they want
  // NB: Hunspell uses underscore to separate language and locale, and Win8 uses
  // dash - if they use the wrong one, just silently replace it for them
  std::string lang = language;
  std::replace(lang.begin(), lang.end(), '_', '-');

  std::wstring wlanguage = ToWString(lang);
  BOOL isSupported;

  if (FAILED(this->spellcheckerFactory->IsSupported(wlanguage.c_str(), &isSupported))) {
    return false;
  }

  if (!isSupported) return false;

  ISpellChecker* currentSpellchecker = NULL;
  if (FAILED(this->spellcheckerFactory->CreateSpellChecker(wlanguage.c_str(), &currentSpellchecker))) {
    return false;
  }
  this->currentSpellcheckers.push_back(currentSpellchecker);

  return true;
}

bool WindowsSpellchecker::SetDictionary(const std::string& language, const std::string& path) {
  if (!this->spellcheckerFactory) {
    return false;
  }

  for (size_t i = 0; i < this->currentSpellcheckers.size(); ++i) {
    ISpellChecker* currentSpellchecker = this->currentSpellcheckers[i];
    currentSpellchecker->Release();
  }
  this->currentSpellcheckers.clear();

  return AddDictionary(language, path);
}

std::vector<std::string> WindowsSpellchecker::GetAvailableDictionaries(const std::string& path) {
  HRESULT hr;

  if (!this->spellcheckerFactory) {
    return std::vector<std::string>();
  }

  IEnumString* langList;
  if (FAILED(hr = this->spellcheckerFactory->get_SupportedLanguages(&langList))) {
    return std::vector<std::string>();
  }

  std::vector<std::string> ret;
  LPOLESTR str;
  while (langList->Next(1, &str, NULL) == S_OK) {
    std::wstring wlang;
    wlang.assign(str);
    ret.push_back(ToUTF8(wlang));

    CoTaskMemFree(str);
  }

  langList->Release();
  return ret;
}

bool WindowsSpellchecker::IsMisspelled(const std::string& word) {
  if (this->currentSpellcheckers.empty()) {
    return false;
  }

  IEnumSpellingError* errors = NULL;
  std::wstring wword = ToWString(word);
  bool ret;
  for (size_t i = 0; i < this->currentSpellcheckers.size(); ++i) {
    ISpellChecker* currentSpellchecker = this->currentSpellcheckers[i];
    errors = NULL;
    if (FAILED(currentSpellchecker->Check(wword.c_str(), &errors))) {
      continue;
    }

    ISpellingError* dontcare;
    HRESULT hr = errors->Next(&dontcare);

    switch (hr) {
    case S_OK:
      // S_OK == There are errors to examine
      ret = true;
      dontcare->Release();
      break;
    case S_FALSE:
      // Worked, but error free
      ret = false;
      break;
    default:
      // Something went pear-shaped
      ret = false;
      break;
    }

    errors->Release();

    if (ret == false) {
      break;
    }
  }

  return ret;
}

std::vector<MisspelledRange> WindowsSpellchecker::CheckSpelling(const uint16_t *text, size_t length) {
  std::vector<MisspelledRange> result;

  if (this->currentSpellcheckers.empty()) {
    return result;
  }

  IEnumSpellingError* errors = NULL;
  std::wstring wtext(reinterpret_cast<const wchar_t *>(text), length);

  for (size_t i = 0; i < this->currentSpellcheckers.size(); ++i) {
    ISpellChecker* currentSpellchecker = this->currentSpellcheckers[i];
    if (FAILED(currentSpellchecker->Check(wtext.c_str(), &errors))) {
      continue;
    }

    std::vector<MisspelledRange> currentResult;

    ISpellingError* error;
    while (errors->Next(&error) == S_OK) {
      ULONG start, length;
      error->get_StartIndex(&start);
      error->get_Length(&length);

      MisspelledRange range;
      range.start = start;
      range.end = start + length;
      currentResult.push_back(range);
      error->Release();
    }

    errors->Release();

    if (currentResult.empty()) {
      return std::vector<MisspelledRange>();
    }
    if (result.empty()) {
      std::swap(result, currentResult);
    } else {
      std::vector<MisspelledRange> intersection;
      std::set_intersection(
        result.begin(), result.end(),
        currentResult.begin(), currentResult.end(),
        std::back_inserter(intersection), compareMisspelledRanges);
      std::swap(result, intersection);
    }
  }

  return result;
}

void WindowsSpellchecker::Add(const std::string& word) {
  if (this->currentSpellcheckers.empty()) {
    return;
  }

  std::wstring wword = ToWString(word);
  this->currentSpellcheckers[0]->Add(wword.c_str());
}

void WindowsSpellchecker::Remove(const std::string& word) {
  // NB: ISpellChecker has no way to remove words from the dictionary
  return;
}


std::vector<std::string> WindowsSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  if (this->currentSpellcheckers.empty()) {
    return std::vector<std::string>();
  }

  std::wstring& wword = ToWString(word);
  IEnumString* words = NULL;
  std::vector<std::string> ret;

  for (size_t i = 0; i < this->currentSpellcheckers.size(); ++i) {
    ISpellChecker* currentSpellchecker = this->currentSpellcheckers[i];
    words = NULL;
    HRESULT hr = currentSpellchecker->Suggest(wword.c_str(), &words);

    if (FAILED(hr)) {
      continue;
    }

    // NB: S_FALSE == word is spelled correctly
    if (hr == S_FALSE) {
      words->Release();
      continue;
    }

    LPOLESTR correction;
    while (words->Next(1, &correction, NULL) == S_OK) {
      std::wstring wcorr;
      wcorr.assign(correction);
      ret.push_back(ToUTF8(wcorr));

      CoTaskMemFree(correction);
    }

    words->Release();
  }

  return ret;
}

SpellcheckerImplementation* SpellcheckerFactory::CreateSpellchecker() {
  WindowsSpellchecker* ret = new WindowsSpellchecker();
  if (ret->IsSupported() && getenv("SPELLCHECKER_PREFER_HUNSPELL") == NULL) {
    return ret;
  }

  delete ret;
  return new HunspellSpellchecker();
}

}  // namespace spellchecker
