#ifndef METHOD_H_
#define METHOD_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "Expression.h"
#include "Feature.h"
#include "FormalParam.h"
#include "support/iterator.h"

namespace lcpl {

class FormalParam;

/// \brief AST node for a method declaration
class Method : public Feature {
  typedef std::vector<std::unique_ptr<FormalParam>> FormalParamsType;

  struct iterator
      : public llvm::iterator_adaptor_base<iterator,
                                           FormalParamsType::const_iterator> {
    explicit iterator(FormalParamsType::const_iterator &&wrapped)
        : iterator_adaptor_base(wrapped) {}
    FormalParam *operator*() const { return I->get(); }
  };

public:
  /// \brief Create a node for a method declaration
  /// \note This will take ownership of \p body and of the \p formalParameters
  ///       if provided
  explicit Method(int lineNumber, const std::string &name,
                  const std::string &returnType,
                  std::unique_ptr<Expression> body = nullptr,
                  const std::vector<FormalParam *> &formalParameters = {})
      : Feature(lineNumber, name), returnType(returnType),
        body(std::move(body)), parameters() {
    for (auto formalParameter : formalParameters) {
      parameters.emplace_back(formalParameter);
    }
  }

  /// \brief Add formal parameter and take ownership of it
  void addParameter(std::unique_ptr<FormalParam> param) {
    parameters.push_back(std::move(param));
  }

  std::string getName() { return name; }
  bool isMethod() const override { return true; }

  /// @{
  /// \brief Iterate through the parameters
  iterator begin() const { return iterator(parameters.begin()); }
  iterator end() const { return iterator(parameters.end()); }
  /// @}

  std::string getReturnType() const { return returnType; }

  Expression *getBody() const { return body.get(); }

private:
  std::string returnType;
  std::unique_ptr<Expression> body;
  FormalParamsType parameters;
};
}
#endif /* METHOD_H_ */
