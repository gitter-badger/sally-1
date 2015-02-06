/*
 * model.h
 *
 *  Created on: Nov 28, 2014
 *      Author: dejan
 */

#pragma once

#include "expr/term_manager.h"

#include <map>
#include <vector>

namespace sally {
namespace expr {

class model {

public:

  typedef std::map<expr::term_ref, expr::term_ref> term_to_value_map;
  typedef term_to_value_map::const_iterator const_iterator;
  typedef term_to_value_map::iterator iterator;

  model(expr::term_manager& tm);

  /** Clear the model */
  void clear();

  /** Set the value of a variable */
  void set_value(expr::term_ref var, expr::term_ref value);

  /** Get the value of a term in the model (not just variables) */
  expr::term_ref get_value(expr::term_ref var) const;

  /** Return true if a variable var has a value in the model */
  bool has_value(expr::term_ref var) const;

  /** Get the iterator for the first of var -> value */
  const_iterator values_begin() const;

  /** Get the iterator for the last of var -> value */
  const_iterator values_end() const;

private:

  /** The term manager */
  expr::term_manager& d_term_manager;

  /** All the variables */
  std::vector<expr::term_ref_strong> d_variables;

  /** The map from variables to their values */
  term_to_value_map d_variable_to_value_map;

  /** Cache of term values */
  term_to_value_map d_term_to_value_map;
};


}
}
