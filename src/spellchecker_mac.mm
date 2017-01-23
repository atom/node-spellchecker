#include "spellchecker_mac.h"
#include "spellchecker_hunspell.h"

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

namespace spellchecker {

static NSString* currentGlobalLanguage = nil;

MacSpellchecker::MacSpellchecker() {
  this->spellCheckerLanguage = nil;
  this->spellChecker = [NSSpellChecker sharedSpellChecker];
}

MacSpellchecker::~MacSpellchecker() {
  [this->spellCheckerLanguage release];
  this->spellCheckerLanguage = nil;
}

bool MacSpellchecker::SetDictionary(const std::string& language) {
  @autoreleasepool {
    [this->spellCheckerLanguage release];

    if (language.length() < 1) {
      this->spellCheckerLanguage = nil;
      this->UpdateGlobalSpellchecker();
      return true;
    }

    this->spellCheckerLanguage = [[NSString alloc] initWithUTF8String: language.c_str()];

    return [this->spellChecker setLanguage: this->spellCheckerLanguage] == YES;
  }
}

bool MacSpellchecker::SetDictionaryToContents(const unsigned char* data, size_t length) {
  return false;
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
    this->UpdateGlobalSpellchecker();

    NSString* misspelling = [NSString stringWithUTF8String:word.c_str()];
    NSRange range = [this->spellChecker checkSpellingOfString:misspelling
                                                   startingAt:0];

    // NB: Corrections will actually return nothing for checkSpellingOfString
    // but _will_ return a correction. 'distopia' will trigger this bug on 10.12
    NSString* correction = [this->spellChecker correctionForWordRange:NSMakeRange(0, misspelling.length)
      inString: misspelling
      language: this->spellChecker.language
      inSpellDocumentWithTag: 0];

    if (correction) return true;

    result = range.length > 0;
  }

  return result;
}

std::vector<MisspelledRange> MacSpellchecker::CheckSpelling(const uint16_t *text, size_t length) {
  std::vector<MisspelledRange> result;

  @autoreleasepool {
    this->UpdateGlobalSpellchecker();

    NSData *data = [[NSData alloc] initWithBytesNoCopy:(void *)(text) length:(length * 2) freeWhenDone:NO];
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF16LittleEndianStringEncoding];
    NSArray *misspellings = [this->spellChecker checkString:string
                                                      range:NSMakeRange(0, string.length)
                                                      types:NSTextCheckingTypeSpelling
                                                    options:nil
                                     inSpellDocumentWithTag:0
                                                orthography:nil
                                                  wordCount:nil];
    for (NSTextCheckingResult *misspelling in misspellings) {
      MisspelledRange range;
      range.start = misspelling.range.location;
      range.end = misspelling.range.location + misspelling.range.length;
      result.push_back(range);
    }

    // NB: Corrections will actually return nothing for checkString
    // but _will_ return a correction. 'distopia' will trigger this bug on 10.12
    NSString* correction = [this->spellChecker correctionForWordRange:NSMakeRange(0, string.length)
      inString: string
      language: this->spellChecker.language
      inSpellDocumentWithTag: 0];

    // NB: This is blatantly wrong
    if (correction) {
      MisspelledRange range;
      range.start = 0;
      range.end = correction.length;
      result.push_back(range);
    }
  }

  return result;
}

void MacSpellchecker::Add(const std::string& word) {
  @autoreleasepool {
    this->UpdateGlobalSpellchecker();

    NSString* newWord = [NSString stringWithUTF8String:word.c_str()];
    [this->spellChecker learnWord:newWord];
  }
}

void MacSpellchecker::Remove(const std::string& word) {
  @autoreleasepool {
    this->UpdateGlobalSpellchecker();

    NSString* newWord = [NSString stringWithUTF8String:word.c_str()];
    [this->spellChecker unlearnWord:newWord];
  }
}

std::vector<std::string> MacSpellchecker::GetCorrectionsForMisspelling(const std::string& word) {
  std::vector<std::string> corrections;

  @autoreleasepool {
    this->UpdateGlobalSpellchecker();

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

    // NB: Corrections will actually return nothing for checkString
    // but _will_ return a correction. 'distopia' will trigger this bug on 10.12
    NSString* correction = [this->spellChecker correctionForWordRange:NSMakeRange(0, misspelling.length)
      inString: misspelling
      language: this->spellChecker.language
      inSpellDocumentWithTag: 0];

    if (correction) {
      std::string to_find = [correction UTF8String];

      if (find(corrections.begin(), corrections.end(), to_find) == corrections.end()) {
        corrections.push_back(to_find);
      }
    }
  }

  return corrections;
}

void MacSpellchecker::UpdateGlobalSpellchecker() {
  const NSString* autoLangauge = @"___AUTO_LANGUAGE";
  NSString* globalLang = currentGlobalLanguage ? currentGlobalLanguage : autoLangauge;
  NSString* ourLang = this->spellCheckerLanguage ? this->spellCheckerLanguage : autoLangauge;

  if ([globalLang isEqualToString: ourLang]) {
    return;
  }

  currentGlobalLanguage = this->spellCheckerLanguage;
  if (!this->spellCheckerLanguage) {
    [this->spellChecker setAutomaticallyIdentifiesLanguages: YES];
  } else {
    [this->spellChecker setAutomaticallyIdentifiesLanguages: NO];
    [this->spellChecker setLanguage: this->spellCheckerLanguage];
  }
}

SpellcheckerImplementation* SpellcheckerFactory::CreateSpellchecker() {
  if (getenv("SPELLCHECKER_PREFER_HUNSPELL")) {
    return new HunspellSpellchecker();
  }

  return new MacSpellchecker();
}

}  // namespace spellchecker
