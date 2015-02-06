/*
 * integer.cpp
 *
 *  Created on: Dec 1, 2014
 *      Author: dejan
 */


#include "expr/integer.h"
#include "utils/output.h"
#include "expr/term_manager.h"

#include <iostream>
#include <cassert>

namespace sally {
namespace expr {

void integer::to_stream(std::ostream& out) const {
  output::language lang = output::get_output_language(out);
  switch (lang) {
  case output::MCMT:
  case output::HORN:
  {
    int sgn = mpz_sgn(d_gmp_int.get_mpz_t());
    if (sgn == 0) {
      out << "0";
    } else {
      if (sgn < 0) {
        // when printing gmp numerator skip the -, but wrap into (- )
        out << "(- " << (d_gmp_int.get_str().c_str() + 1) << ")";
      } else {
        // just regular print
        out << d_gmp_int.get_str();
      }
    }
    break;
  }
  case output::NUXMV:
    out << d_gmp_int.get_str();
    break;
  case output::LUSTRE:
    // TODO: handle integer arithmetic
    out << d_gmp_int.get_str() << ".0";
    break;
  default:
    assert(false);
  }
}

std::ostream& operator << (std::ostream& out, const integer& z) {
  z.to_stream(out);
  return out;
}

integer integer::operator + (const integer& other) const {
  return integer(d_gmp_int + other.d_gmp_int);
}

integer& integer::operator += (const integer& other) {
  d_gmp_int += other.d_gmp_int;
  return *this;
}

integer integer::operator - () const {
  return integer(-d_gmp_int);
}

integer integer::operator - (const integer& other) const {
  return integer(d_gmp_int - other.d_gmp_int);
}

integer& integer::operator -= (const integer& other) {
  d_gmp_int -= other.d_gmp_int;
  return *this;
}

integer integer::operator * (const integer& other) const {
  return integer(d_gmp_int * other.d_gmp_int);
}
integer& integer::operator *= (const integer& other) {
  d_gmp_int *= other.d_gmp_int;
  return *this;
}

bool integer::operator < (const integer& other) const {
  return d_gmp_int < other.d_gmp_int;
}

bool integer::operator <= (const integer& other) const {
  return d_gmp_int <= other.d_gmp_int;
}

bool integer::operator > (const integer& other) const {
  return d_gmp_int > other.d_gmp_int;
}

bool integer::operator >= (const integer& other) const {
  return d_gmp_int >= other.d_gmp_int;
}

integer::integer(const term_manager& tm, term_ref t) {
  const term& t_term = tm.term_of(t);
  assert(t_term.op() == CONST_INTEGER);
  *this = tm.get_integer_constant(t_term);
}

}
}
