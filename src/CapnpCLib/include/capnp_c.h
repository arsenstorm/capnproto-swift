#ifndef CAPNP_C_H
#define CAPNP_C_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int capnp_c_version_major(void);
int capnp_c_version_minor(void);
int capnp_c_version_micro(void);

typedef struct capnp_message_builder capnp_message_builder_t;
typedef struct capnp_message_reader capnp_message_reader_t;

capnp_message_builder_t* capnp_c_message_builder_new(void);
void capnp_c_message_builder_free(capnp_message_builder_t* builder);

// Returns a newly allocated byte buffer containing the flat (unpacked) message.
// Caller must free it with capnp_c_free.
uint8_t* capnp_c_message_builder_to_bytes(
  capnp_message_builder_t* builder,
  size_t* out_size
);

// Returns an opaque pointer to the underlying capnp::MallocMessageBuilder.
// Only C++ code should reinterpret this pointer.
void* capnp_c_message_builder_get(capnp_message_builder_t* builder);

// Create readers from unpacked or packed message bytes.
capnp_message_reader_t* capnp_c_message_reader_new_unpacked(
  const uint8_t* bytes,
  size_t size
);
capnp_message_reader_t* capnp_c_message_reader_new_packed(
  const uint8_t* bytes,
  size_t size
);
void capnp_c_message_reader_free(capnp_message_reader_t* reader);

// Returns an opaque pointer to the underlying capnp::MessageReader.
// Only C++ code should reinterpret this pointer.
void* capnp_c_message_reader_get(capnp_message_reader_t* reader);

void capnp_c_free(void* ptr);

#ifdef __cplusplus
}
#endif

#endif // CAPNP_C_H
