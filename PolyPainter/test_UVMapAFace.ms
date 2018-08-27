(
global MicroPaint_CanvasRollout
try (destroyDialog MicroPaint_CanvasRollout) catch()
local isDrawing = false
local bitmapX = bitmapY = 512
local theCanvasBitmap = bitmap bitmapX bitmapY color:white
 
rollout MicroPaint_CanvasRollout "MicroPaint"
(
 bitmap theCanvas pos:[0,0] width:bitmapX height:bitmapY bitmap:theCanvasBitmap
 fn paintBrush pos =
 (
  setPixels theCanvasBitmap pos #(black)
  theCanvas.bitmap = theCanvasBitmap
 )
 on MicroPaint_CanvasRollout lbuttondown pos do
 (
  isDrawing = true
  paintBrush pos
 )
 on MicroPaint_CanvasRollout lbuttonup pos do isDrawing = false
 on MicroPaint_CanvasRollout mousemove pos do if isDrawing do paintBrush pos
)
createDialog MicroPaint_CanvasRollout bitmapX bitmapY
)