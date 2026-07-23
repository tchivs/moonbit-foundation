// Portable CRC-32 and Adler-32 checksums for MoonBit Native Foundation.
//
// CRC-32 (IEEE 802.3 polynomial 0xEDB88320) is used by PNG chunk integrity
// and ZIP/PDF stream checksums. Adler-32 is used by zlib/DEFLATE.
//
// Both implementations use UInt64 internally for consistency with the rest
// of the MNF core (which uses checked UInt64 arithmetic throughout). The
// mathematical result is a 32-bit checksum stored in the low 32 bits.
// A precomputed lookup table enables byte-at-a-time processing without
// allocation per step.

// ---------------------------------------------------------------------------
// CRC-32 (IEEE 802.3, polynomial 0xEDB88320, reflected)
// ---------------------------------------------------------------------------

///|
/// Precomputed CRC-32 lookup table (256 entries).
let crc32_table : Array[UInt64] = build_crc32_table()

///|
fn build_crc32_table() -> Array[UInt64] {
  let table : Array[UInt64] = []
  for i = 0; i < 256; i = i + 1 {
    let mut crc = i.to_uint64()
    for _j = 0; _j < 8; _j = _j + 1 {
      if (crc & 1UL) != 0UL {
        crc = (crc >> 1) ^ 0xedb88320UL
      } else {
        crc = crc >> 1
      }
    }
    table.push(crc)
  }
  table
}

///|
/// Compute the CRC-32 checksum of a byte slice.
///
/// Uses the standard IEEE 802.3 polynomial (0xEDB88320 reflected). The
/// result is the final checksum as a `UInt64` (low 32 bits hold the value).
/// An empty input returns `0x0000000000000000`.
pub fn crc32(bytes : Array[Byte]) -> UInt64 {
  let mut crc = 0xffffffffUL
  for i = 0; i < bytes.length(); i = i + 1 {
    let idx = ((crc ^ bytes[i].to_uint64()) & 0xffUL).to_int()
    crc = (crc >> 8) ^ crc32_table[idx]
  }
  crc ^ 0xffffffffUL
}

///|
/// Update a running CRC-32 with a single byte.
///
/// `initial` should be the current CRC value (use `0xffffffffUL` to start).
/// The result must be XORed with `0xffffffffUL` only once at the very end;
/// intermediate calls pass the raw running value.
pub fn crc32_update(initial : UInt64, byte : Byte) -> UInt64 {
  let idx = ((initial ^ byte.to_uint64()) & 0xffUL).to_int()
  (initial >> 8) ^ crc32_table[idx]
}

// ---------------------------------------------------------------------------
// Adler-32 (RFC 1950 / zlib)
// ---------------------------------------------------------------------------

///|
/// Compute the Adler-32 checksum of a byte slice.
///
/// Uses modulo 65521 as specified by RFC 1950. An empty input returns `1UL`
/// (the Adler-32 of zero-length data).
pub fn adler32(bytes : Array[Byte]) -> UInt64 {
  let mut a : UInt64 = 1UL
  let mut b : UInt64 = 0UL
  for i = 0; i < bytes.length(); i = i + 1 {
    a = (a + bytes[i].to_uint64()) % 65521UL
    b = (b + a) % 65521UL
  }
  (b << 16) | a
}

///|
/// Update a running Adler-32 with a single byte.
///
/// `initial` should be the current Adler-32 value (use `1UL` to start).
/// The result is the updated value; no finalization step is needed.
pub fn adler32_update(initial : UInt64, byte : Byte) -> UInt64 {
  let a = (initial & 0xffffUL) + byte.to_uint64()
  let a_mod = if a >= 65521UL {
    a - 65521UL
  } else {
    a
  }
  let b = (initial >> 16) + a_mod
  let b_mod = if b >= 65521UL {
    b - 65521UL
  } else {
    b
  }
  (b_mod << 16) | a_mod
}
