#include "define_transition.h"

#include <iostream>

namespace sally {
namespace cmd {

void define_transition_command::run(system::context* ctx, engine* e) {
  ctx->add_transition_formula(d_id, d_formula);
  d_formula = 0;
}

define_transition_command::~define_transition_command() {
  delete d_formula;
}

void define_transition_command::to_stream(std::ostream& out) const {
  out << "[" << get_command_type_string() << "(" << d_id << "): ";
  out << *d_formula;
  out << "]";
}

define_transition_command::define_transition_command(std::string id, system::transition_formula* formula)
: command(DEFINE_TRANSITION)
, d_id(id)
, d_formula(formula)
{
}

}
}
