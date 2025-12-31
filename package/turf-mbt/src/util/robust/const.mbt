///|
/// 2^27 + 1, multiplier for splitting double precision floating point numbers
let splitter : Double = 134217729.0

///|
/// Relative error bound for double precision floating point (2^-53)
let epsilon : Double = 0.00000000000000011102230246251565

///|
/// Result error bound
let result_err_bound : Double = (3.0 + 8.0 * epsilon) * epsilon
