#include "spellchecker.h"

#include <node.h>
#include <node_internals.h>
using namespace v8;

namespace {

Handle<Value> IsMisspelled(const Arguments& args) {
  if (args.Length() < 1)
    return node::ThrowError("Bad argument");

  std::string word = *String::Utf8Value(args[0]);
  return v8::Boolean::New(spellchecker::IsMisspelled(word));
}

Handle<Value> GetCorrectionsForMisspelling(const Arguments& args) {
  if (args.Length() < 1)
    return node::ThrowError("Bad argument");

  std::string word = *String::Utf8Value(args[0]);
  std::vector<std::string> corrections =
    spellchecker::GetCorrectionsForMisspelling(word);

  Local<Array> result = Array::New(corrections.size());
  for (size_t i = 0; i < corrections.size(); ++i) {
    const std::string& word = corrections[i];
    result->Set(i, v8::String::New(word.data(), word.size()));
  }

  return result;
}

void Init(Handle<Object> exports) {
  exports->Set(String::NewSymbol("isMisspelled"),
      FunctionTemplate::New(IsMisspelled)->GetFunction());
  exports->Set(String::NewSymbol("getCorrectionsForMisspelling"),
      FunctionTemplate::New(GetCorrectionsForMisspelling)->GetFunction());
}

}

NODE_MODULE(spellchecker, Init)
