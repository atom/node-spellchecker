#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

#include <node.h>
#include <v8.h>

using namespace v8;

Handle<Value> IsMisspelled(const Arguments& args) {
  HandleScope scope;

  if (args.Length() < 1)
    return ThrowException(Exception::Error(String::New("Bad argument.")));

  bool result;
  NSString *word = [NSString
      stringWithUTF8String:(*String::Utf8Value(args[0]))];
  NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
  @synchronized(spellChecker) {
    NSRange range = [spellChecker checkSpellingOfString:word startingAt:0];
    result = range.length > 0;
  }
  return scope.Close(v8::Boolean::New(result));
}

Handle<Value> GetCorrectionsForMisspelling(const Arguments& args) {
  HandleScope scope;

  if (args.Length() < 1)
    return ThrowException(Exception::Error(String::New("Bad argument.")));

  Handle<Value> result;
  NSString *misspelling = [NSString
      stringWithUTF8String:(*String::Utf8Value(args[0]))];
  NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
  @synchronized(spellChecker) {
    NSString *language = [spellChecker language];
    NSRange range;
    range.location = 0;
    range.length = [misspelling length];
    NSArray *guesses = [spellChecker guessesForWordRange:range
                                                inString:misspelling
                                                language:language
                                  inSpellDocumentWithTag:0];
    Handle<Array> v8Guesses = Array::New([guesses count]);
    for (uint32_t i = 0; i < v8Guesses->Length(); i++) {
      v8Guesses->Set(i, String::New([[guesses objectAtIndex:i] UTF8String]));
    }
    result = v8Guesses;
  }
  return scope.Close(result);
}

void init(Handle<Object> exports) {
  exports->Set(String::NewSymbol("isMisspelled"),
      FunctionTemplate::New(IsMisspelled)->GetFunction());
  exports->Set(String::NewSymbol("getCorrectionsForMisspelling"),
      FunctionTemplate::New(GetCorrectionsForMisspelling)->GetFunction());
}

NODE_MODULE(nsspellchecker, init)

