///|
/// Tests for Crockford's Base32 encoding/decoding
/// Alphabet: 0123456789ABCDEFGHJKMNPQRSTVWXYZ (excludes I, L, O, U)
test "encode_char: maps 5-bit values to Crockford's Base32 characters" {
  // First 10 characters are digits 0-9
  inspect(encode_char(0), content="0")
  inspect(encode_char(1), content="1")
  inspect(encode_char(9), content="9")
  // Next 22 characters are letters (excluding I, L, O, U)
  inspect(encode_char(10), content="A")
  inspect(encode_char(11), content="B")
  inspect(encode_char(17), content="H")
  inspect(encode_char(18), content="J") // skips I
  inspect(encode_char(19), content="K")
  inspect(encode_char(20), content="M") // skips L
  inspect(encode_char(21), content="N")
  inspect(encode_char(22), content="P") // skips O
  inspect(encode_char(31), content="Z")
}

///|
test "decode_char: maps Crockford's Base32 characters to 5-bit values" {
  // Digits
  inspect(decode_char('0'), content="Ok(0)")
  inspect(decode_char('9'), content="Ok(9)")
  // Letters (uppercase)
  inspect(decode_char('A'), content="Ok(10)")
  inspect(decode_char('H'), content="Ok(17)")
  inspect(decode_char('J'), content="Ok(18)")
  inspect(decode_char('Z'), content="Ok(31)")
  // Letters (lowercase) - should be case insensitive
  inspect(decode_char('a'), content="Ok(10)")
  inspect(decode_char('z'), content="Ok(31)")
  // Special mappings: I/i -> 1, L/l -> 1, O/o -> 0
  inspect(decode_char('I'), content="Ok(1)")
  inspect(decode_char('i'), content="Ok(1)")
  inspect(decode_char('L'), content="Ok(1)")
  inspect(decode_char('l'), content="Ok(1)")
  inspect(decode_char('O'), content="Ok(0)")
  inspect(decode_char('o'), content="Ok(0)")
  // Invalid characters
  inspect(decode_char('U'), content="Err(\"Invalid Base32 character: U\")")
  inspect(decode_char('!'), content="Err(\"Invalid Base32 character: !\")")
}

///|
test "encode_timestamp: encodes 48-bit timestamp to 10 characters" {
  // Minimum timestamp (0)
  inspect(encode_timestamp(0L), content="0000000000")
  // Known timestamp: 1469918176385 (from ULID spec example)
  inspect(encode_timestamp(1469918176385L), content="01ARYZ6S41")
  // Maximum valid timestamp (2^48 - 1)
  inspect(encode_timestamp(281474976710655L), content="7ZZZZZZZZZ")
}

///|
test "encode_randomness: encodes 80-bit randomness to 16 characters" {
  // All zeros
  let zeros : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  inspect(encode_randomness(zeros), content="0000000000000000")
  // All ones (0xFF)
  let ones : FixedArray[Byte] = FixedArray::make(10, b'\xFF')
  inspect(encode_randomness(ones), content="ZZZZZZZZZZZZZZZZ")
}

///|
test "decode_timestamp: decodes 10 characters to 48-bit timestamp" {
  inspect(decode_timestamp("0000000000"), content="Ok(0)")
  inspect(decode_timestamp("01ARYZ6S41"), content="Ok(1469918176385)")
  inspect(decode_timestamp("7ZZZZZZZZZ"), content="Ok(281474976710655)")
  // Case insensitive
  inspect(decode_timestamp("01aryz6s41"), content="Ok(1469918176385)")
  // Invalid length
  inspect(
    decode_timestamp("012345678"),
    content="Err(\"Invalid timestamp length: expected 10, got 9\")",
  )
}

///|
test "decode_randomness: decodes 16 characters to 80-bit randomness" {
  let zeros = decode_randomness("0000000000000000")
  inspect(zeros is Ok(_), content="true")
  let ones = decode_randomness("ZZZZZZZZZZZZZZZZ")
  inspect(ones is Ok(_), content="true")
}

///|
test "decode_char: decodes all 32 valid Crockford's Base32 characters" {
  // Test all 32 characters: 0-9, A-H, J-K, M-N, P-T, V-Z
  let encoding_alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  for i = 0; i < 32; i = i + 1 {
    let c = encoding_alphabet[i].to_int().unsafe_to_char()
    match decode_char(c) {
      Ok(value) => inspect(value == i, content="true")
      Err(_) => inspect(false, content="true") // Should not error
    }
  }
}

///|
test "encode/decode timestamp roundtrip: maximum timestamp" {
  // Maximum 48-bit timestamp: 2^48 - 1 = 281474976710655
  let max_timestamp = 281474976710655L
  let encoded = encode_timestamp(max_timestamp)
  inspect(encoded, content="7ZZZZZZZZZ")
  match decode_timestamp(encoded) {
    Ok(decoded) => inspect(decoded == max_timestamp, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "encode/decode randomness roundtrip: maximum randomness" {
  // All 0xFF bytes
  let max_randomness : FixedArray[Byte] = FixedArray::make(10, b'\xFF')
  let encoded = encode_randomness(max_randomness)
  inspect(encoded, content="ZZZZZZZZZZZZZZZZ")
  match decode_randomness(encoded) {
    Ok(decoded) =>
      for i = 0; i < 10; i = i + 1 {
        inspect(decoded[i] == b'\xFF', content="true")
      }
    Err(_) => inspect(false, content="true")
  }
}
