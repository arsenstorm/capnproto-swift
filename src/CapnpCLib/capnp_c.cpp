#include "capnp_c.h"

#include <capnp/common.h>

int capnp_c_version_major(void) {
  return CAPNP_VERSION_MAJOR;
}

int capnp_c_version_minor(void) {
  return CAPNP_VERSION_MINOR;
}

int capnp_c_version_micro(void) {
  return CAPNP_VERSION_MICRO;
}
