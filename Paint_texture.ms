R = Ray ($Dummy01.pos) ($Dummy02.pos)
Arr = (IntersectRayEx $GeoSphere01 R)
Point pos:(Arr[1]).pos

s = $GeoSphere01
tf = getTVFace s arr[2]

tv1 = getTVert s tf.x
tv2 = getTVert s tf.y
tv3 = getTVert s tf.z

v
tx = s.Material.DiffuseMap
m = tx.BitMap
for i=1 to 100 do
(
	x = random 1 20
	y = random 1 20
SetPixels m [(tv.x*m.width+x), (m.height-tv.y*m.height+y)] #((color 255 255 0))
)

tx.filtering = tx.filtering


