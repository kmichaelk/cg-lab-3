import {
  StandardRenderer,
  RendererConfiguration,
  createRenderingContext
} from './renderer'
import './styles/main.css'

document.querySelector<HTMLDivElement>('#app')!.innerHTML = `
  <div style="text-align: center">
    <h2 style="margin: 2px">Лабораторная работа №3</h2>
    <h3 style="margin: 2px">Трассировка лучей</h3>
  </div>
  <div class="canvas-wrapper">
    <canvas id="rendition" width="512" height="512"></canvas>
  </div>
  <span id="fps"></span>
`

const fpsLabel = document.querySelector<HTMLSpanElement>('#fps')!

//

const context = createRenderingContext(document.querySelector<HTMLCanvasElement>('#rendition')!)
const config: RendererConfiguration = {

}

const render = () => {
  context.configure(config)

  context.clear()
  context.render()
  context.flush()
}

context.setRenderer(StandardRenderer)
render()

let lastFrameTime = 0
const rerender = () => {
  context.clear()
  context.render()
  context.flush()

  const fps = 1 / ((performance.now() - lastFrameTime) / 1000)
  lastFrameTime = performance.now()

  fpsLabel.innerText = `${fps.toFixed(2)} FPS`

  requestAnimationFrame(rerender)
}

//requestAnimationFrame(rerender)
