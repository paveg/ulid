///|
/// Tests for ULID validation and comparison

test "is_valid: accepts valid ULID strings" {
  inspect(is_valid("01ARYZ6S410000000000000000"), content="true")
  inspect(is_valid("00000000000000000000000000"), content="true")
  inspect(is_valid("7ZZZZZZZZZZZZZZZZZZZZZZZZZ"), content="true")
  // Lowercase is valid
  inspect(is_valid("01aryz6s410000000000000000"), content="true")
}

test "is_valid: rejects invalid ULID strings" {
  // Too short
  inspect(is_valid("01ARYZ6S41"), content="false")
  // Too long
  inspect(is_valid("01ARYZ6S41000000000000000000"), content="false")
  // Invalid character U
  inspect(is_valid("01ARYZ6S41000000000000000U"), content="false")
  // Overflow (first char > 7)
  inspect(is_valid("80000000000000000000000000"), content="false")
}

test "ULID::compare: orders ULIDs lexicographically" {
  let ulid1 = ULID::from_string("00000000000000000000000000").unwrap()
  let ulid2 = ULID::from_string("00000000010000000000000000").unwrap()
  let ulid3 = ULID::from_string("01ARYZ6S410000000000000000").unwrap()

  // ulid1 < ulid2 < ulid3
  inspect(ulid1.compare(ulid2) < 0, content="true")
  inspect(ulid2.compare(ulid3) < 0, content="true")
  inspect(ulid1.compare(ulid3) < 0, content="true")

  // Reverse comparison
  inspect(ulid3.compare(ulid1) > 0, content="true")

  // Equal comparison
  let ulid1_copy = ULID::from_string("00000000000000000000000000").unwrap()
  inspect(ulid1.compare(ulid1_copy) == 0, content="true")
}

test "ULID::op_equal: checks equality" {
  let ulid1 = ULID::from_string("01ARYZ6S410000000000000000").unwrap()
  let ulid2 = ULID::from_string("01ARYZ6S410000000000000000").unwrap()
  let ulid3 = ULID::from_string("01ARYZ6S410000000000000001").unwrap()

  inspect(ulid1 == ulid2, content="true")
  inspect(ulid1 == ulid3, content="false")
}

test "ULID sorting: ULIDs sort correctly" {
  let ulid1 = ULID::from_string("01ARYZ6S410000000000000000").unwrap()
  let ulid2 = ULID::from_string("00000000000000000000000000").unwrap()
  let ulid3 = ULID::from_string("7ZZZZZZZZZZZZZZZZZZZZZZZZZ").unwrap()

  // Manual sorting check using compare
  let arr = [ulid1, ulid2, ulid3]
  arr.sort_by(fn(a, b) { a.compare(b) })

  inspect(arr[0].to_string(), content="00000000000000000000000000")
  inspect(arr[1].to_string(), content="01ARYZ6S410000000000000000")
  inspect(arr[2].to_string(), content="7ZZZZZZZZZZZZZZZZZZZZZZZZZ")
}

test "ULID timestamp ordering: same timestamp ULIDs sort by randomness" {
  let rand = @random.Rand::chacha8()
  fn get_time() -> Int64 { 1469918176385L }
  let gen = MonotonicGenerator::new(get_time, rand)

  let ulid1 = gen.generate()
  let ulid2 = gen.generate()
  let ulid3 = gen.generate()

  // Monotonic generator ensures strict ordering
  inspect(ulid1.compare(ulid2) < 0, content="true")
  inspect(ulid2.compare(ulid3) < 0, content="true")
}
