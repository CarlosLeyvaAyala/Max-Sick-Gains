import { weightInterpolation } from "../common"

/** Gets muscle definition level by interpolating two points.
 *
 * @param x Value to interpolate at (usually, `weight` or `gains`).
 * @param lo Minimum muscle definition allowed.
 * @param hi Maximum muscle definition allowed.
 * @returns Final muscle definition.
 */
export function getMuscleDef(x: number, lo: number, hi: number) {
  return Math.round(weightInterpolation(x, lo, hi))
}
