/**
 * This file is part of sally.
 * Copyright (C) 2015 SRI International.
 *
 * Sally is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Sally is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with sally.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "factory.h"

#include "utils/exception.h"
#include "utils/module_setup.h"

#include <vector>
#include <map>

namespace sally {
namespace ai {

/** Type for setting up individual engines */
class interpreter_data : public module_data<abstract_interpreter, system::context> {
public:
  interpreter_data();
};

/** Map from id's to engine information */
static interpreter_data s_interpreter_data;

abstract_interpreter* factory::mk_interpreter(std::string id, const system::context& ctx) {
  return s_interpreter_data.get_module_info(id).new_instance(ctx);
}

void factory::setup_options(boost::program_options::options_description& options) {
  for (interpreter_data::const_iterator it = s_interpreter_data.data().begin(); it != s_interpreter_data.data().end(); ++ it) {
    std::stringstream ss;
    ss << "Abstract interpreter '" << it->second->get_id() << "' options";
    boost::program_options::options_description engine_options(ss.str());
    it->second->setup_options(engine_options);
    if (engine_options.options().size() > 0) {
      options.add(engine_options);
    }
  }
}

void factory::get_interpreters(std::vector<std::string>& out) {
  for (interpreter_data::const_iterator it = s_interpreter_data.data().begin(); it != s_interpreter_data.data().end(); ++ it) {
    out.push_back(it->second->get_id());
  }
}

}
}

#include "ai_list.h"
