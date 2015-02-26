#include "nan.h"
#include "spellchecker.h"

using node::ObjectWrap;
using namespace spellchecker;
using namespace v8;

namespace {

class Spellchecker : public ObjectWrap {
  SpellcheckerImplementation* impl;

  static NAN_METHOD(New) {
    NanScope();
    Spellchecker* that = new Spellchecker();
    that->Wrap(args.This());

    NanReturnValue(args.This());
  }

  static NAN_METHOD(SetDictionary) {
    NanScope();

    if (args.Length() < 1) {
      return NanThrowError("Bad argument");
    }

    Spellchecker* that = ObjectWrap::Unwrap<Spellchecker>(args.Holder());

    std::string language = *String::Utf8Value(args[0]);
    std::string directory = ".";
    if (args.Length() > 1) {
      directory = *String::Utf8Value(args[1]);
    }

    that->impl->SetDictionary(language, directory);
    NanReturnUndefined();
  }

  static NAN_METHOD(IsMisspelled) {
    NanScope();
    if (args.Length() < 1) {
      return NanThrowError("Bad argument");
    }

    Spellchecker* that = ObjectWrap::Unwrap<Spellchecker>(args.Holder());
    std::string word = *String::Utf8Value(args[0]);

    NanReturnValue(NanNew<Boolean>(that->impl->IsMisspelled(word)));
  }

  static NAN_METHOD(GetCorrectionsForMisspelling) {
    NanScope();
    if (args.Length() < 1) {
      return NanThrowError("Bad argument");
    }

    Spellchecker* that = ObjectWrap::Unwrap<Spellchecker>(args.Holder());

    std::string word = *String::Utf8Value(args[0]);
    std::vector<std::string> corrections =
      that->impl->GetCorrectionsForMisspelling(word);

    Local<Array> result = NanNew<Array>(corrections.size());
    for (size_t i = 0; i < corrections.size(); ++i) {
      const std::string& word = corrections[i];
      result->Set(i, NanNew<String>(word.data(), word.size()));
    }

    NanReturnValue(result);
  }

  Spellchecker() {
    impl = SpellcheckerFactory::CreateSpellchecker();
  }

  // actual destructor
  virtual ~Spellchecker() {
    delete impl;
  }

 public:
  static void Init(Handle<Object> exports) {
    Local<FunctionTemplate> tpl = NanNew<FunctionTemplate>(Spellchecker::New);

    tpl->SetClassName(NanNew<String>("Spellchecker"));
    tpl->InstanceTemplate()->SetInternalFieldCount(1);

    NODE_SET_METHOD(tpl->InstanceTemplate(), "setDictionary", Spellchecker::SetDictionary);
    NODE_SET_METHOD(tpl->InstanceTemplate(), "getCorrectionsForMisspelling", Spellchecker::GetCorrectionsForMisspelling);
    NODE_SET_METHOD(tpl->InstanceTemplate(), "isMisspelled", Spellchecker::IsMisspelled);

    exports->Set(NanNew("Spellchecker"), tpl->GetFunction());
  }
};

void Init(Handle<Object> exports, Handle<Object> module) {
  Spellchecker::Init(exports);
}

}  // namespace

NODE_MODULE(spellchecker, Init)
