#include <windows.h>
#include <guiddef.h>
#include <initguid.h>
#include <string>
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
  this->currentSpellchecker = NULL;

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
  if (this->spellcheckerFactory) {
    this->spellcheckerFactory->Release();
  }

  if (InterlockedDecrement(&g_COMRefcount) == 0) {
    CoUninitialize();
  }
}

bool WindowsSpellchecker::IsSupported() {
  return !(g_COMFailed || (spellcheckerFactory == NULL));
}

bool WindowsSpellchecker::SetDictionary(const std::string& language, const std::string& path) {
  HRESULT hr;

  if (this->currentSpellchecker != NULL) {
    this->currentSpellchecker->Release();
    this->currentSpellchecker = NULL;
  }

  // Figure out if we have a dictionary installed for the language they want
  std::wstring wlanguage = ToWString(language);
  BOOL isSupported;

  if (FAILED(this->spellcheckerFactory->IsSupported(wlanguage.c_str(), &isSupported))) {
    return false;
  }

  if (!isSupported) return false;

  if (FAILED(this->spellcheckerFactory->CreateSpellChecker(wlanguage.c_str(), &this->currentSpellchecker))) {
    return false;
  }

  return true;
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
  if (this->currentSpellchecker == NULL) {
    return false;
  }

  IEnumSpellingError* errors = NULL;
  std::wstring wword = ToWString(word);
  if (FAILED(this->currentSpellchecker->Check(wword.c_str(), &errors))) {
    return false;
  }

  bool ret;

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
  return ret;
}

std::vector<std::string> WindowsSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  if (this->currentSpellchecker == NULL) {
    return std::vector<std::string>();
  }

  std::wstring& wword = ToWString(word);
  IEnumString* words = NULL;

  HRESULT hr = this->currentSpellchecker->Suggest(wword.c_str(), &words);

  if (FAILED(hr)) {
    return std::vector<std::string>();
  }

  // NB: S_FALSE == word is spelled correctly
  if (hr == S_FALSE) {
    words->Release();
    return std::vector<std::string>();
  }

  std::vector<std::string> ret;

  LPOLESTR correction;
  while (words->Next(1, &correction, NULL) == S_OK) {
    std::wstring wcorr;
    wcorr.assign(correction);
    ret.push_back(ToUTF8(wcorr));

    CoTaskMemFree(correction);
  }

  words->Release();
  return ret;
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
