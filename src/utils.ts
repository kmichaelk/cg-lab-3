export function clamp(val: number, min: number, max: number) {
  return val < min ? min : val > max ? max : val
}

export default function debounce(fn: () => any, timeout = 300) {
  let timeoutId: number
  return () => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(fn, timeout)
  }
}
