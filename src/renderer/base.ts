import { Renderer, RendererConfiguration } from './types'

interface Base2DRendererState {
  config: RendererConfiguration
}

export const BaseRenderer = ({
  render,
  dispose
}: {
  render: (state: Base2DRendererState) => void
  dispose: () => void
}): Renderer => {
  let state: Base2DRendererState | null = null

  return {
    render() {
      render(state!)
    },
    configure(config) {
      if (state == null) {
        state = {
          config: structuredClone(config),
        }
      } else {
        state.config = structuredClone(config)
      }
    },
    dispose() {
      dispose()
    }
  }
}
