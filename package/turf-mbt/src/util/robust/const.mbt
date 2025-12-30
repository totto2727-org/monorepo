///|
/// 2^27 + 1、倍精度浮動小数点を分割するための乗数
let splitter : Double = 134217729.0

///|
/// 倍精度浮動小数点の相対誤差境界 (2^-53)
let epsilon : Double = 0.00000000000000011102230246251565

///|
/// 結果の誤差境界
let result_err_bound : Double = (3.0 + 8.0 * epsilon) * epsilon
