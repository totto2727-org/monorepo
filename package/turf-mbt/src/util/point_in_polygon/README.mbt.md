# Point in Polygon

元にしたJS実装：<https://github.com/rowanwins/point-in-polygon-hao/blob/938b2be31d326c52c8f6cffbbb1c59bae4d609bc/src/index.js>

## 元の実装との差異

元ライブラリで参照している[JS用のRobust実装](https://github.com/mourner/robust-predicates)には以下のような表記がある。

```md
Note: unlike J. Shewchuk's original code, all the functions in this library assume y axis is oriented downwards ↓, so the semantics are different.
```

本ライブラリのRobust実装は、通常の座標系を採用しているため、元の実装とは一部の計算の符号が逆転している。
