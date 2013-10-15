#ifndef SRC_SPELLCHECKER_H_
#define SRC_SPELLCHECKER_H_

#include <string>
#include <vector>

namespace spellchecker {

// Initializes everything.
void Init(const std::string& dirname);

// Returns true if the word is misspelled.
bool IsMisspelled(const std::string& word);

// Returns an array containing possible corrections for the word.
std::vector<std::string> GetCorrectionsForMisspelling(const std::string& word);

}  // namespace spellchecker

#endif  // SRC_SPELLCHECKER_H_
