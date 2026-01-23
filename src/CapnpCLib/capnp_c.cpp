#include "capnp_c.h"

#include <capnp/common.h>
#include <capnp/message.h>
#include <capnp/serialize.h>
#include <capnp/serialize-packed.h>
#include <capnp/any.h>
#include <kj/array.h>
#include <kj/io.h>

#include <cstdlib>
#include <cstring>
#include <memory>

struct capnp_message_builder {
  capnp::MallocMessageBuilder builder;
};

struct capnp_message_reader {
  kj::Array<capnp::word> words;
  kj::Array<kj::byte> bytes;
  std::unique_ptr<capnp::MessageReader> reader;
};

int capnp_c_version_major(void) {
  return CAPNP_VERSION_MAJOR;
}

int capnp_c_version_minor(void) {
  return CAPNP_VERSION_MINOR;
}

int capnp_c_version_micro(void) {
  return CAPNP_VERSION_MICRO;
}

capnp_message_builder_t* capnp_c_message_builder_new(void) {
  try {
    return new capnp_message_builder();
  } catch (...) {
    return nullptr;
  }
}

void capnp_c_message_builder_free(capnp_message_builder_t* builder) {
  delete builder;
}

uint8_t* capnp_c_message_builder_to_bytes(
  capnp_message_builder_t* builder,
  size_t* out_size
) {
  if (!builder) {
    return nullptr;
  }

  try {
    // Ensure a root exists so serialization succeeds.
    builder->builder.getRoot<capnp::AnyPointer>();

    auto words = capnp::messageToFlatArray(builder->builder);
    auto bytes = words.asBytes();
    size_t size = bytes.size();
    auto* out = static_cast<uint8_t*>(std::malloc(size));
    if (!out) {
      return nullptr;
    }
    std::memcpy(out, bytes.begin(), size);
    if (out_size) {
      *out_size = size;
    }
    return out;
  } catch (...) {
    return nullptr;
  }
}

void* capnp_c_message_builder_get(capnp_message_builder_t* builder) {
  if (!builder) {
    return nullptr;
  }
  return &builder->builder;
}

capnp_message_reader_t* capnp_c_message_reader_new_unpacked(
  const uint8_t* bytes,
  size_t size
) {
  if (!bytes || size == 0 || (size % sizeof(capnp::word)) != 0) {
    return nullptr;
  }

  try {
    auto* reader = new capnp_message_reader();
    size_t word_count = size / sizeof(capnp::word);
    reader->words = kj::heapArray<capnp::word>(word_count);
    std::memcpy(reader->words.begin(), bytes, size);
    reader->reader = std::make_unique<capnp::FlatArrayMessageReader>(
      reader->words.asPtr()
    );
    return reader;
  } catch (...) {
    return nullptr;
  }
}

capnp_message_reader_t* capnp_c_message_reader_new_packed(
  const uint8_t* bytes,
  size_t size
) {
  if (!bytes || size == 0) {
    return nullptr;
  }

  try {
    auto* reader = new capnp_message_reader();
    reader->bytes = kj::heapArray<kj::byte>(size);
    std::memcpy(reader->bytes.begin(), bytes, size);
    kj::ArrayInputStream input(reader->bytes.asPtr());
    reader->reader = std::make_unique<capnp::PackedMessageReader>(input);
    return reader;
  } catch (...) {
    return nullptr;
  }
}

void capnp_c_message_reader_free(capnp_message_reader_t* reader) {
  delete reader;
}

void* capnp_c_message_reader_get(capnp_message_reader_t* reader) {
  if (!reader || !reader->reader) {
    return nullptr;
  }
  return reader->reader.get();
}

void capnp_c_free(void* ptr) {
  std::free(ptr);
}
