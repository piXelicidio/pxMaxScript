--para el viewPort Activo
--y el Width y Heihgt actual
function Point3toScreen Vector =
(
	thePos = Vector * viewport.getTM()
	screen_origin = mapScreenToView [0,0] (thePos.z) [RenderWidth, RenderHeight]
	end_screen = mapScreenToView [RenderWidth, RenderHeight] (thePos.z) [RenderWidth, RenderHeight]
	world_size = screen_origin-end_screen
	x_aspect = RenderWidth/(abs world_size.x)
	y_aspect = RenderHeight/(abs world_size.y)
	screen_coords = point2 (x_aspect*(thePos.x-screen_origin.x)) (-(y_aspect*(thePos.y-screen_origin.y)))
	Return screen_coords
) 

Point3toScreen $.position
