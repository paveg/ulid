///|
/// ULID Generator with injectable time source and random generator
///
/// Since MoonBit's standard library doesn't have a built-in way to get the
/// current system time (runtime-dependent), the time source is injected as
/// a function parameter.

/// ULID Generator using injected time source and random generator
pub struct Generator {
  get_time : () -> Int64
  rand : @random.Rand
}

/// Create a new ULID generator
///
/// Parameters:
/// - `get_time`: Function that returns current Unix timestamp in milliseconds
/// - `rand`: Random number generator from @random module
pub fn Generator::new(get_time : () -> Int64, rand : @random.Rand) -> Generator {
  { get_time, rand }
}

/// Generate a new ULID using current time
pub fn Generator::generate(self : Generator) -> ULID {
  let timestamp = (self.get_time)()
  self.generate_from_timestamp(timestamp)
}

/// Generate a ULID with a specific timestamp
pub fn Generator::generate_from_timestamp(self : Generator, timestamp : Int64) -> ULID {
  let randomness = generate_randomness(self.rand)
  ULID::from_parts(timestamp, randomness)
}

/// Generate 80 bits (10 bytes) of randomness
fn generate_randomness(rand : @random.Rand) -> FixedArray[Byte] {
  let bytes : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  // Generate random bytes using uint64
  let r1 = rand.uint64()
  let r2 = rand.uint64()

  // First 8 bytes from r1
  bytes[0] = ((r1 >> 56) & 0xFFUL).to_byte()
  bytes[1] = ((r1 >> 48) & 0xFFUL).to_byte()
  bytes[2] = ((r1 >> 40) & 0xFFUL).to_byte()
  bytes[3] = ((r1 >> 32) & 0xFFUL).to_byte()
  bytes[4] = ((r1 >> 24) & 0xFFUL).to_byte()
  bytes[5] = ((r1 >> 16) & 0xFFUL).to_byte()
  bytes[6] = ((r1 >> 8) & 0xFFUL).to_byte()
  bytes[7] = (r1 & 0xFFUL).to_byte()

  // Last 2 bytes from r2
  bytes[8] = ((r2 >> 56) & 0xFFUL).to_byte()
  bytes[9] = ((r2 >> 48) & 0xFFUL).to_byte()

  bytes
}

/// Monotonic ULID Generator
///
/// Generates ULIDs that are guaranteed to be strictly increasing within
/// the same millisecond by incrementing the random component.
pub struct MonotonicGenerator {
  get_time : () -> Int64
  rand : @random.Rand
  mut last_time : Int64
  last_randomness : FixedArray[Byte]
}

/// Create a new monotonic ULID generator
pub fn MonotonicGenerator::new(get_time : () -> Int64, rand : @random.Rand) -> MonotonicGenerator {
  {
    get_time,
    rand,
    last_time: 0L,
    last_randomness: FixedArray::make(10, b'\x00'),
  }
}

/// Generate a new monotonic ULID
///
/// If called multiple times within the same millisecond, the random
/// component is incremented to ensure strict ordering.
pub fn MonotonicGenerator::generate(self : MonotonicGenerator) -> ULID {
  let timestamp = (self.get_time)()

  let randomness = if timestamp == self.last_time {
    // Same millisecond: increment the randomness
    increment_randomness(self.last_randomness)
  } else {
    // New millisecond: generate fresh randomness
    generate_randomness(self.rand)
  }

  self.last_time = timestamp
  // Copy randomness to last_randomness
  for i = 0; i < 10; i = i + 1 {
    self.last_randomness[i] = randomness[i]
  }

  ULID::from_parts(timestamp, randomness)
}

/// Increment the randomness by 1 (with carry propagation)
fn increment_randomness(randomness : FixedArray[Byte]) -> FixedArray[Byte] {
  let result : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  for i = 0; i < 10; i = i + 1 {
    result[i] = randomness[i]
  }

  // Increment from least significant byte (index 9) with carry
  let mut carry = 1
  for i = 9; i >= 0 && carry > 0; i = i - 1 {
    let sum = result[i].to_int() + carry
    result[i] = (sum & 0xFF).to_byte()
    carry = sum >> 8
  }

  result
}
