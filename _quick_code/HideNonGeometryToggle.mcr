macroScript HideNonGeometry category:"pX Tools" buttonText:"Hide Non-Geometry Toggle"
(
	if hideByCategory.bones == false then
	(		
		hideByCategory.geometry = false
		hideByCategory.shapes = true
		hideByCategory.lights = true
		hideByCategory.cameras = true
		hideByCategory.helpers = true
		hideByCategory.spacewarps = true
		hideByCategory.particles = true
		hideByCategory.bones = true
	) else
	(
		hideByCategory.none()
	)
)