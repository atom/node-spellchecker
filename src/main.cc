#include <node.h>
#include <v8.h>

using namespace v8;

extern Handle<Value> IsMisspelled(const Arguments& args);
extern Handle<Value> GetCorrectionsForMisspelling(const Arguments& args);

void init(Handle<Object> exports) {
  exports->Set(String::NewSymbol("isMisspelled"),
      FunctionTemplate::New(IsMisspelled)->GetFunction());
  exports->Set(String::NewSymbol("getCorrectionsForMisspelling"),
      FunctionTemplate::New(GetCorrectionsForMisspelling)->GetFunction());
}

NODE_MODULE(spellchecker, init)
