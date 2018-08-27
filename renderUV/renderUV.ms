
for i=1 to objects.count do
(
	select( objects[i] )
	m = objects[i].modifiers["Unwrap UVW"]
	if m!= undefined then
	(
		s = print objects[i].name
		m.renderUV ("uvmap_"+s+".png")
	)
)