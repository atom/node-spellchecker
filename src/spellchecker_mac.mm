#include "spellchecker_mac.h"

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

namespace spellchecker {

void MacSpellchecker::SetDictionary(const std::string& language, const std::string& path) {
}

bool MacSpellchecker::IsMisspelled(const std::string& word) {
  bool result;

  @autoreleasepool {
    NSString* misspelling = [NSString stringWithUTF8String:word.c_str()];
    NSSpellChecker* spellChecker = [NSSpellChecker sharedSpellChecker];
    @synchronized(spellChecker) {
      NSRange range = [spellChecker checkSpellingOfString:misspelling
                                               startingAt:0];
      result = range.length > 0;
    }
  }
  return result;
}

std::vector<std::string> MacSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  std::vector<std::string> corrections;

  @autoreleasepool {
    NSString* misspelling = [NSString stringWithUTF8String:word.c_str()];
    NSSpellChecker* spellChecker = [NSSpellChecker sharedSpellChecker];
    @synchronized(spellChecker) {
      NSString* language = [spellChecker language];
      NSRange range;
      range.location = 0;
      range.length = [misspelling length];
      NSArray* guesses = [spellChecker guessesForWordRange:range
                                                  inString:misspelling
                                                  language:language
                                    inSpellDocumentWithTag:0];

      corrections.reserve(guesses.count);
      for (size_t i = 0; i < guesses.count; ++i)
        corrections.push_back([[guesses objectAtIndex:i] UTF8String]);
    }
  }
  return corrections;
}

SpellcheckerImplementation* SpellcheckerFactory::CreateSpellchecker() {
  return new MacSpellchecker();
}

}  // namespace spellchecker
