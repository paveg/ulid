///|
/// ULID (Universally Unique Lexicographically Sortable Identifier)
///
/// A ULID consists of:
/// - 48-bit timestamp (milliseconds since Unix epoch)
/// - 80-bit randomness

///|
/// ULID structure holding 128-bit identifier
pub struct ULID {
  /// 48-bit Unix timestamp in milliseconds
  timestamp_ : Int64
  /// 80-bit cryptographically random value (10 bytes)
  randomness_ : FixedArray[Byte]
}

///|
/// Create a ULID from timestamp and randomness parts
pub fn ULID::from_parts(
  timestamp : Int64,
  randomness : FixedArray[Byte],
) -> ULID {
  // Copy randomness to ensure immutability
  let rand_copy : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  for i = 0; i < 10; i = i + 1 {
    rand_copy[i] = randomness[i]
  }
  { timestamp_: timestamp, randomness_: rand_copy }
}

///|
/// Get the timestamp component (milliseconds since Unix epoch)
pub fn ULID::timestamp(self : ULID) -> Int64 {
  self.timestamp_
}

///|
/// Get the randomness component as a copy
pub fn ULID::randomness(self : ULID) -> FixedArray[Byte] {
  let copy : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  for i = 0; i < 10; i = i + 1 {
    copy[i] = self.randomness_[i]
  }
  copy
}

///|
/// Convert ULID to its canonical 26-character string representation
pub fn ULID::to_string(self : ULID) -> String {
  let timestamp_str = encode_timestamp(self.timestamp_)
  let randomness_str = encode_randomness(self.randomness_)
  timestamp_str + randomness_str
}

///|
/// Parse a ULID from its 26-character string representation
pub fn ULID::from_string(s : String) -> Result[ULID, String] {
  if s.length() != 26 {
    return Err("Invalid ULID length: expected 26, got \{s.length()}")
  }

  // Check for overflow: first character must be 0-7
  let first_char = s[0].to_int()
  if first_char >= '8'.to_int() && first_char <= 'Z'.to_int() {
    // Check if it's a valid Base32 char that would cause overflow
    let c = first_char.unsafe_to_char()
    match decode_char(c) {
      Ok(value) =>
        if value > 7 {
          return Err(
            "ULID overflow: first character indicates value > 128 bits",
          )
        }
      Err(e) => return Err(e)
    }
  }

  // Extract timestamp part (first 10 chars)
  let timestamp_str = try {
    s[0:10].to_string()
  } catch {
    _ => return Err("Failed to extract timestamp part")
  }
  // Extract randomness part (last 16 chars)
  let randomness_str = try {
    s[10:26].to_string()
  } catch {
    _ => return Err("Failed to extract randomness part")
  }
  match decode_timestamp(timestamp_str) {
    Err(e) => Err(e)
    Ok(timestamp) =>
      match decode_randomness(randomness_str) {
        Err(e) => Err(e)
        Ok(randomness) => Ok(ULID::from_parts(timestamp, randomness))
      }
  }
}

///|
/// Convert ULID to 16-byte binary representation (big-endian)
pub fn ULID::to_bytes(self : ULID) -> FixedArray[Byte] {
  let bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')

  // First 6 bytes: timestamp (48 bits, big-endian)
  let t = self.timestamp_
  bytes[0] = ((t >> 40) & 0xFFL).to_byte()
  bytes[1] = ((t >> 32) & 0xFFL).to_byte()
  bytes[2] = ((t >> 24) & 0xFFL).to_byte()
  bytes[3] = ((t >> 16) & 0xFFL).to_byte()
  bytes[4] = ((t >> 8) & 0xFFL).to_byte()
  bytes[5] = (t & 0xFFL).to_byte()

  // Last 10 bytes: randomness
  for i = 0; i < 10; i = i + 1 {
    bytes[6 + i] = self.randomness_[i]
  }
  bytes
}

///|
/// Create ULID from 16-byte binary representation (big-endian)
pub fn ULID::from_bytes(bytes : FixedArray[Byte]) -> Result[ULID, String] {
  if bytes.length() != 16 {
    return Err("Invalid ULID bytes length: expected 16, got \{bytes.length()}")
  }

  // Extract timestamp from first 6 bytes (big-endian)
  let timestamp = (bytes[0].to_int64() << 40) |
    (bytes[1].to_int64() << 32) |
    (bytes[2].to_int64() << 24) |
    (bytes[3].to_int64() << 16) |
    (bytes[4].to_int64() << 8) |
    bytes[5].to_int64()

  // Extract randomness from last 10 bytes
  let randomness : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  for i = 0; i < 10; i = i + 1 {
    randomness[i] = bytes[6 + i]
  }
  Ok(ULID::from_parts(timestamp, randomness))
}

///|
/// Validate a ULID string without parsing
pub fn is_valid(s : String) -> Bool {
  if s.length() != 26 {
    return false
  }

  // Check first character for overflow (must be 0-7 in Base32)
  let first_char = s[0].to_int().unsafe_to_char()
  match decode_char(first_char) {
    Err(_) => return false
    Ok(value) => if value > 7 { return false }
  }

  // Check all characters are valid Base32
  for i = 1; i < 26; i = i + 1 {
    let c = s[i].to_int().unsafe_to_char()
    match decode_char(c) {
      Err(_) => return false
      Ok(_) => ()
    }
  }
  true
}

///|
/// Compare two ULIDs lexicographically
/// Returns negative if self < other, zero if equal, positive if self > other
pub fn ULID::compare(self : ULID, other : ULID) -> Int {
  // First compare timestamps
  if self.timestamp_ < other.timestamp_ {
    return -1
  }
  if self.timestamp_ > other.timestamp_ {
    return 1
  }

  // Timestamps are equal, compare randomness byte by byte
  for i = 0; i < 10; i = i + 1 {
    let a = self.randomness_[i].to_int()
    let b = other.randomness_[i].to_int()
    if a < b {
      return -1
    }
    if a > b {
      return 1
    }
  }
  0
}

///|
/// Implement equality for ULID
pub impl Eq for ULID with equal(self, other) {
  self.compare(other) == 0
}
