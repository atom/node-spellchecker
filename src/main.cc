#include "spellchecker.h"

#include "nan.h"
using namespace v8;

namespace {

NAN_METHOD(PlatformInit) {
  NanScope();
  spellchecker::Init(*String::Utf8Value(args[0]));
  NanReturnUndefined();
}

NAN_METHOD(IsMisspelled) {
  NanScope();
  if (args.Length() < 1)
    return NanThrowError("Bad argument");

  std::string word = *String::Utf8Value(args[0]);
  NanReturnValue(Boolean::New(spellchecker::IsMisspelled(word)));
}

NAN_METHOD(GetCorrectionsForMisspelling) {
  NanScope();
  if (args.Length() < 1)
    return NanThrowError("Bad argument");

  std::string word = *String::Utf8Value(args[0]);
  std::vector<std::string> corrections =
    spellchecker::GetCorrectionsForMisspelling(word);

  Local<Array> result = Array::New(corrections.size());
  for (size_t i = 0; i < corrections.size(); ++i) {
    const std::string& word = corrections[i];
    result->Set(i, String::New(word.data(), word.size()));
  }

  NanReturnValue(result);
}

void Init(Handle<Object> exports) {
  NODE_SET_METHOD(exports, "init", PlatformInit);
  NODE_SET_METHOD(exports, "isMisspelled", IsMisspelled);
  NODE_SET_METHOD(exports,
                  "getCorrectionsForMisspelling",
                  GetCorrectionsForMisspelling);
}

}  // namespace

NODE_MODULE(spellchecker, Init)
