#include "spellchecker_mac.h"

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

namespace spellchecker {


MacSpellchecker::MacSpellchecker() {
  this->spellChecker = [[NSSpellChecker alloc] init];
  [this->spellChecker setAutomaticallyIdentifiesLanguages: NO];
}

MacSpellchecker::~MacSpellchecker() {
  [this->spellChecker release];
}


bool MacSpellchecker::SetDictionary(const std::string& language, const std::string& path) {
  @autoreleasepool {
    NSString* lang = [NSString stringWithUTF8String: language.c_str()];
    return [this->spellChecker setLanguage: lang] == YES;
  }
}

std::vector<std::string> MacSpellchecker::GetAvailableDictionaries(const std::string& path) {
  std::vector<std::string> ret;

  @autoreleasepool {
    NSArray* languages = [this->spellChecker availableLanguages];

    for (size_t i = 0; i < languages.count; ++i) {
      ret.push_back([[languages objectAtIndex:i] UTF8String]);
    }
  }

  return ret;
}

bool MacSpellchecker::IsMisspelled(const std::string& word) {
  bool result;

  @autoreleasepool {
    NSString* misspelling = [NSString stringWithUTF8String:word.c_str()];
    NSRange range = [this->spellChecker checkSpellingOfString:misspelling
                                                   startingAt:0];

    result = range.length > 0;
  }

  return result;
}

void MacSpellchecker::Add(const std::string& word) {
  @autoreleasepool {
    NSString* newWord = [NSString stringWithUTF8String:word.c_str()];
    [this->spellChecker learnWord:newWord];
  }
}

std::vector<std::string> MacSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  std::vector<std::string> corrections;

  @autoreleasepool {
    NSString* misspelling = [NSString stringWithUTF8String:word.c_str()];
    NSString* language = [this->spellChecker language];
    NSRange range;

    range.location = 0;
    range.length = [misspelling length];

    NSArray* guesses = [this->spellChecker guessesForWordRange:range
                                                      inString:misspelling
                                                      language:language
                                        inSpellDocumentWithTag:0];

    corrections.reserve(guesses.count);

    for (size_t i = 0; i < guesses.count; ++i) {
      corrections.push_back([[guesses objectAtIndex:i] UTF8String]);
    }
  }

  return corrections;
}

SpellcheckerImplementation* SpellcheckerFactory::CreateSpellchecker() {
  return new MacSpellchecker();
}

}  // namespace spellchecker
