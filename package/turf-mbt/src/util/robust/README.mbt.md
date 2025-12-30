# Robust Geometric Predicates

Jonathan Richard Shewchukの高精度浮動小数点演算アルゴリズムのMoonBit移植。

参照: <https://www.cs.cmu.edu/~quake/robust.html>

元にしたRust実装：<https://github.com/georust/robust/blob/654f34cb8cdb3ae21bf59ef3472f92652942cd74/src/lib.rs>

## 概要

浮動小数点演算の丸め誤差による幾何学的判定の不正確さを解決するための適応的精度アルゴリズム。

## 主要関数

### orient2d(point_a_x, point_a_y, point_b_x, point_b_y, point_c_x, point_c_y) -> Double

3点(pa, pb, pc)の配置方向を判定する。

- **正の値**: `pc`が直線`pa→pb`の**左側**（反時計回り）
- **負の値**: `pc`が直線`pa→pb`の**右側**（時計回り）
- **0**: 3点が同一直線上（共線）

参照：<https://gemini.google.com/share/2af46502682f>

### orient3d(...) -> Double

4点(pa, pb, pc, pd)の配置関係を判定する。

- **正の値**: `pd`が面`pa-pb-pc`の表側（外側）にある
- **負の値**: `pd`が面`pa-pb-pc`の裏側（内側）にある
- **0**: 4点が同一平面上にある

### incircle(...) -> Double

3点(pa, pb, pc)が反時計回りに並んでいるとき、点pdがその外接円の内部にあるか判定する。

- **正の値**: `pd`が円の内部にある
- **負の値**: `pd`が円の外部にある
- **0**: `pd`が円周上にある

### insphere(...) -> Double

4点(pa, pb, pc, pd)が反時計回りに並んでいるとき、点peがその外接球の内部にあるか判定する。

- **正の値**: `pe`が球の内部にある
- **負の値**: `pe`が球の外部にある
- **0**: `pe`が球面上にある

## アルゴリズムの段階

1. **高速パス**: 単純な行列式計算で判定可能か確認
2. **適応的精度**: 必要な場合のみ高精度計算を実行

## 低レベル演算

### Two-Sum / Two-Diff

誤差なしの加減算を実現する基本演算。

```moonbit
two_sum(a, b) -> (x, y) // a + b = x + y (exact)
two_diff(a, b) -> (x, y) // a - b = x + y (exact)
```

### Two-Product

誤差なしの乗算を実現。`split`関数で仮数部を分割し、部分積の誤差を補正。

```moonbit
two_product(a, b) -> (x, y) // a * b = x + y (exact)
```

### Expansion Arithmetic

可変精度の数値（expansion）同士の演算。

- `fast_expansion_sum_zeroelim`: 2つのExpansionの和
- `scale_expansion_zeroelim`: Expansionとスカラの積
