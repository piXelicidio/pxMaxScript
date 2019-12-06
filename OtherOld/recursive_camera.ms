progressStart "Recursive rendering..."
count = 4
for i=1 to 8 do
(
	progressUpdate ((i*100)/4)
	renderbmp = (render camera:$camera02 vfb:off )
	renderbmp.filename = "rendertest.bmp"
	save renderbmp
	meditMaterials[1].diffusemap.bitmap = renderbmp		
)
progressEnd()
render camera:$camera02