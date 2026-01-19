///|
/// Tests for ULID struct and core functions
test "ULID::from_parts: creates ULID from timestamp and randomness" {
  let randomness : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let ulid = ULID::from_parts(1469918176385L, randomness)
  inspect(ulid.timestamp(), content="1469918176385")
}

///|
test "ULID::to_string: converts ULID to 26-character string" {
  let randomness : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let ulid = ULID::from_parts(1469918176385L, randomness)
  // Timestamp: 01ARYZ6S41, Randomness: 0000000000000000
  inspect(ulid.to_string(), content="01ARYZ6S410000000000000000")
}

///|
test "ULID::from_string: parses valid 26-character ULID string" {
  let result = ULID::from_string("01ARYZ6S410000000000000000")
  inspect(result is Ok(_), content="true")
  match result {
    Ok(ulid) => {
      inspect(ulid.timestamp(), content="1469918176385")
      inspect(ulid.to_string(), content="01ARYZ6S410000000000000000")
    }
    Err(_) => ()
  }
}

///|
test "ULID::from_string: handles case insensitivity" {
  let upper = ULID::from_string("01ARYZ6S410000000000000000")
  let lower = ULID::from_string("01aryz6s410000000000000000")
  match (upper, lower) {
    (Ok(u), Ok(l)) => inspect(u.to_string() == l.to_string(), content="true")
    _ => ()
  }
}

///|
test "ULID::from_string: rejects invalid length" {
  let result = ULID::from_string("01ARYZ6S41")
  inspect(result is Err(_), content="true")
}

///|
test "ULID::from_string: rejects invalid characters" {
  let result = ULID::from_string("01ARYZ6S41000000000000000U")
  inspect(result is Err(_), content="true")
}

///|
test "ULID::from_string: rejects overflow (first char > 7)" {
  // First character must be 0-7 to prevent 128-bit overflow
  let result = ULID::from_string("80000000000000000000000000")
  inspect(result is Err(_), content="true")
}

///|
test "ULID::to_bytes: converts ULID to 16-byte binary" {
  let randomness : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  let ulid = ULID::from_parts(0L, randomness)
  let bytes = ulid.to_bytes()
  inspect(bytes.length(), content="16")
  // All bytes should be zero
  let mut all_zero = true
  for i = 0; i < 16; i = i + 1 {
    if bytes[i] != b'\x00' {
      all_zero = false
    }
  }
  inspect(all_zero, content="true")
}

///|
test "ULID::from_bytes: creates ULID from 16-byte binary" {
  let bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  let result = ULID::from_bytes(bytes)
  inspect(result is Ok(_), content="true")
  match result {
    Ok(ulid) => {
      inspect(ulid.timestamp(), content="0")
      inspect(ulid.to_string(), content="00000000000000000000000000")
    }
    Err(_) => ()
  }
}

///|
test "ULID::from_bytes: rejects invalid length" {
  let bytes : FixedArray[Byte] = FixedArray::make(15, b'\x00')
  let result = ULID::from_bytes(bytes)
  inspect(result is Err(_), content="true")
}

///|
test "ULID roundtrip: string -> ULID -> string" {
  let original = "01ARYZ6S41DEADBEEFDEADBEEF"
  match ULID::from_string(original) {
    Ok(ulid) => inspect(ulid.to_string(), content="01ARYZ6S41DEADBEEFDEADBEEF")
    Err(_) => ()
  }
}

///|
test "ULID roundtrip: bytes -> ULID -> bytes" {
  let original : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  original[0] = b'\x01'
  original[5] = b'\xFF'
  original[15] = b'\xAB'
  match ULID::from_bytes(original) {
    Ok(ulid) => {
      let bytes = ulid.to_bytes()
      inspect(bytes[0] == original[0], content="true")
      inspect(bytes[5] == original[5], content="true")
      inspect(bytes[15] == original[15], content="true")
    }
    Err(_) => ()
  }
}

///|
test "ULID roundtrip: maximum ULID string" {
  // Maximum valid ULID: 7ZZZZZZZZZZZZZZZZZZZZZZZZZ
  let max_ulid_str = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ"
  match ULID::from_string(max_ulid_str) {
    Ok(ulid) => {
      inspect(ulid.to_string(), content="7ZZZZZZZZZZZZZZZZZZZZZZZZZ")
      // Maximum timestamp: 2^48 - 1
      inspect(ulid.timestamp(), content="281474976710655")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "ULID::from_string: rejects empty string" {
  let result = ULID::from_string("")
  inspect(result is Err(_), content="true")
}
