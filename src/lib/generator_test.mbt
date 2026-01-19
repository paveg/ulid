///|
/// Tests for ULID Generator
test "Generator::new: creates generator with time function and random source" {
  let rand = @random.Rand::chacha8()
  fn get_time() -> Int64 {
    1469918176385L
  }

  let gen = Generator::new(get_time, rand)
  let ulid = gen.generate()
  // Timestamp should match
  inspect(ulid.timestamp(), content="1469918176385")
  // String should start with timestamp encoding
  let s = ulid.to_string()
  inspect(s[0:10].to_string(), content="01ARYZ6S41")
}

///|
test "Generator::generate: produces different ULIDs each call" {
  let rand = @random.Rand::chacha8()
  fn get_time() -> Int64 {
    1469918176385L
  }

  let gen = Generator::new(get_time, rand)
  let ulid1 = gen.generate()
  let ulid2 = gen.generate()
  // Same timestamp
  inspect(ulid1.timestamp() == ulid2.timestamp(), content="true")
  // Different randomness (with overwhelming probability)
  inspect(ulid1.to_string() != ulid2.to_string(), content="true")
}

///|
test "Generator::generate_from_timestamp: uses provided timestamp" {
  let rand = @random.Rand::chacha8()
  fn get_time() -> Int64 {
    0L
  }

  let gen = Generator::new(get_time, rand)
  let ulid = gen.generate_from_timestamp(1234567890123L)
  inspect(ulid.timestamp(), content="1234567890123")
}

///|
test "MonotonicGenerator::new: creates monotonic generator" {
  let rand = @random.Rand::chacha8()
  fn get_time() -> Int64 {
    1469918176385L
  }

  let gen = MonotonicGenerator::new(get_time, rand)
  let ulid = gen.generate()
  inspect(ulid.timestamp(), content="1469918176385")
}

///|
test "MonotonicGenerator::generate: increments within same millisecond" {
  let rand = @random.Rand::chacha8()
  fn get_time() -> Int64 {
    1469918176385L
  }

  let gen = MonotonicGenerator::new(get_time, rand)
  let ulid1 = gen.generate()
  let ulid2 = gen.generate()
  let ulid3 = gen.generate()

  // All should have same timestamp
  inspect(ulid1.timestamp() == ulid2.timestamp(), content="true")
  inspect(ulid2.timestamp() == ulid3.timestamp(), content="true")

  // ULIDs should be strictly increasing (lexicographically)
  inspect(ulid1.to_string() < ulid2.to_string(), content="true")
  inspect(ulid2.to_string() < ulid3.to_string(), content="true")
}

///|
test "MonotonicGenerator::generate: new randomness on new millisecond" {
  let mut current_time = 1469918176385L
  fn get_time() -> Int64 {
    current_time
  }

  let rand = @random.Rand::chacha8()
  let gen = MonotonicGenerator::new(get_time, rand)
  let ulid1 = gen.generate()
  inspect(ulid1.timestamp(), content="1469918176385")

  // Advance time
  current_time = 1469918176386L
  let ulid2 = gen.generate()
  inspect(ulid2.timestamp(), content="1469918176386")

  // Different timestamp, so not necessarily incrementing randomness
  inspect(ulid1.timestamp() < ulid2.timestamp(), content="true")
}
