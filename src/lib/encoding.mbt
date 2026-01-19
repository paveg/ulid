///|
/// Crockford's Base32 encoding/decoding for ULID
/// Alphabet: 0123456789ABCDEFGHJKMNPQRSTVWXYZ (excludes I, L, O, U)

/// The Crockford's Base32 encoding alphabet
let encoding_chars : String = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

/// Encode a 5-bit value (0-31) to a Crockford's Base32 character
pub fn encode_char(value : Int) -> Char {
  encoding_chars[value].to_int().unsafe_to_char()
}

/// Decode a Crockford's Base32 character to a 5-bit value (0-31)
/// Handles case insensitivity and I/L -> 1, O -> 0 mappings
pub fn decode_char(c : Char) -> Result[Int, String] {
  match c {
    '0' | 'O' | 'o' => Ok(0)
    '1' | 'I' | 'i' | 'L' | 'l' => Ok(1)
    '2' => Ok(2)
    '3' => Ok(3)
    '4' => Ok(4)
    '5' => Ok(5)
    '6' => Ok(6)
    '7' => Ok(7)
    '8' => Ok(8)
    '9' => Ok(9)
    'A' | 'a' => Ok(10)
    'B' | 'b' => Ok(11)
    'C' | 'c' => Ok(12)
    'D' | 'd' => Ok(13)
    'E' | 'e' => Ok(14)
    'F' | 'f' => Ok(15)
    'G' | 'g' => Ok(16)
    'H' | 'h' => Ok(17)
    'J' | 'j' => Ok(18)
    'K' | 'k' => Ok(19)
    'M' | 'm' => Ok(20)
    'N' | 'n' => Ok(21)
    'P' | 'p' => Ok(22)
    'Q' | 'q' => Ok(23)
    'R' | 'r' => Ok(24)
    'S' | 's' => Ok(25)
    'T' | 't' => Ok(26)
    'V' | 'v' => Ok(27)
    'W' | 'w' => Ok(28)
    'X' | 'x' => Ok(29)
    'Y' | 'y' => Ok(30)
    'Z' | 'z' => Ok(31)
    _ => Err("Invalid Base32 character: \{c}")
  }
}

/// Encode a 48-bit timestamp to 10 Crockford's Base32 characters
pub fn encode_timestamp(timestamp : Int64) -> String {
  let buf = StringBuilder::new()
  let chars = FixedArray::make(10, '0')
  let mut t = timestamp
  // Encode from right to left (least significant first)
  for i = 9; i >= 0; i = i - 1 {
    chars[i] = encode_char((t & 0x1FL).to_int())
    t = t >> 5
  }
  for i = 0; i < 10; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

/// Encode 80-bit randomness (10 bytes) to 16 Crockford's Base32 characters
pub fn encode_randomness(bytes : FixedArray[Byte]) -> String {
  let chars = FixedArray::make(16, '0')
  // Convert 10 bytes (80 bits) to 16 characters (80 bits)
  // Each character represents 5 bits
  // Byte layout: [0][1][2][3][4][5][6][7][8][9]
  // Char layout: each 5 bits maps to one character

  // Character 0: bits 0-4 of byte 0
  chars[0] = encode_char((bytes[0].to_int() >> 3) & 0x1F)
  // Character 1: bits 5-7 of byte 0 + bits 0-1 of byte 1
  chars[1] = encode_char(((bytes[0].to_int() & 0x07) << 2) | ((bytes[1].to_int() >> 6) & 0x03))
  // Character 2: bits 2-6 of byte 1
  chars[2] = encode_char((bytes[1].to_int() >> 1) & 0x1F)
  // Character 3: bit 7 of byte 1 + bits 0-3 of byte 2
  chars[3] = encode_char(((bytes[1].to_int() & 0x01) << 4) | ((bytes[2].to_int() >> 4) & 0x0F))
  // Character 4: bits 4-7 of byte 2 + bit 0 of byte 3
  chars[4] = encode_char(((bytes[2].to_int() & 0x0F) << 1) | ((bytes[3].to_int() >> 7) & 0x01))
  // Character 5: bits 1-5 of byte 3
  chars[5] = encode_char((bytes[3].to_int() >> 2) & 0x1F)
  // Character 6: bits 6-7 of byte 3 + bits 0-2 of byte 4
  chars[6] = encode_char(((bytes[3].to_int() & 0x03) << 3) | ((bytes[4].to_int() >> 5) & 0x07))
  // Character 7: bits 3-7 of byte 4
  chars[7] = encode_char(bytes[4].to_int() & 0x1F)

  // Second half (bytes 5-9)
  chars[8] = encode_char((bytes[5].to_int() >> 3) & 0x1F)
  chars[9] = encode_char(((bytes[5].to_int() & 0x07) << 2) | ((bytes[6].to_int() >> 6) & 0x03))
  chars[10] = encode_char((bytes[6].to_int() >> 1) & 0x1F)
  chars[11] = encode_char(((bytes[6].to_int() & 0x01) << 4) | ((bytes[7].to_int() >> 4) & 0x0F))
  chars[12] = encode_char(((bytes[7].to_int() & 0x0F) << 1) | ((bytes[8].to_int() >> 7) & 0x01))
  chars[13] = encode_char((bytes[8].to_int() >> 2) & 0x1F)
  chars[14] = encode_char(((bytes[8].to_int() & 0x03) << 3) | ((bytes[9].to_int() >> 5) & 0x07))
  chars[15] = encode_char(bytes[9].to_int() & 0x1F)

  let buf = StringBuilder::new()
  for i = 0; i < 16; i = i + 1 {
    buf.write_char(chars[i])
  }
  buf.to_string()
}

/// Decode 10 Crockford's Base32 characters to a 48-bit timestamp
pub fn decode_timestamp(s : String) -> Result[Int64, String] {
  if s.length() != 10 {
    return Err("Invalid timestamp length: expected 10, got \{s.length()}")
  }
  let mut timestamp = 0L
  for i = 0; i < 10; i = i + 1 {
    let c = s[i].to_int().unsafe_to_char()
    match decode_char(c) {
      Ok(value) => timestamp = (timestamp << 5) | value.to_int64()
      Err(e) => return Err(e)
    }
  }
  Ok(timestamp)
}

/// Decode 16 Crockford's Base32 characters to 80-bit randomness (10 bytes)
pub fn decode_randomness(s : String) -> Result[FixedArray[Byte], String] {
  if s.length() != 16 {
    return Err("Invalid randomness length: expected 16, got \{s.length()}")
  }
  let values = FixedArray::make(16, 0)
  for i = 0; i < 16; i = i + 1 {
    let c = s[i].to_int().unsafe_to_char()
    match decode_char(c) {
      Ok(value) => values[i] = value
      Err(e) => return Err(e)
    }
  }
  let bytes : FixedArray[Byte] = FixedArray::make(10, b'\x00')

  // Decode first 8 characters to first 5 bytes
  bytes[0] = ((values[0] << 3) | (values[1] >> 2)).to_byte()
  bytes[1] = ((values[1] << 6) | (values[2] << 1) | (values[3] >> 4)).to_byte()
  bytes[2] = ((values[3] << 4) | (values[4] >> 1)).to_byte()
  bytes[3] = ((values[4] << 7) | (values[5] << 2) | (values[6] >> 3)).to_byte()
  bytes[4] = ((values[6] << 5) | values[7]).to_byte()

  // Decode last 8 characters to last 5 bytes
  bytes[5] = ((values[8] << 3) | (values[9] >> 2)).to_byte()
  bytes[6] = ((values[9] << 6) | (values[10] << 1) | (values[11] >> 4)).to_byte()
  bytes[7] = ((values[11] << 4) | (values[12] >> 1)).to_byte()
  bytes[8] = ((values[12] << 7) | (values[13] << 2) | (values[14] >> 3)).to_byte()
  bytes[9] = ((values[14] << 5) | values[15]).to_byte()

  Ok(bytes)
}
