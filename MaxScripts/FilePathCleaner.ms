-- FilePathCleaner by piXel, 4/2005 pxtracer@gmail.com

-- Supress path from filename of TextureMaps.
-- Process Maps if exists.. 
-- (DiffuseMap, SpecularMap, OpacityMap, BumpMap, SelfIlumMap, 
--  ReflectionMap, RefractionMap, TranslucentColor)



a = #()
for i=1 to SceneMaterials.count do
(
	m = SceneMaterials[i]
	try (a[1]= m.DiffuseMap) catch (print "undefined Map")
	try (a[2]= m.BumpMap) catch (print "undefined Map")
	try (a[3]= m.SpecularMap) catch (print "undefined Map")
	try (a[4]= m.OpacityMap) catch (print "undefined Map")
	try (a[5]= m.SelfIlumMap) catch (print "undefined Map")
	try (a[6]= m.ReflectionMap) catch (print "undefined Map")
	try (a[7]= m.RefractionMap) catch (print "undefined Map")
	try (a[8]= m.TranslucentColor) catch (print "undefined Map")
	for j = 1 to a.count do
	(
		if (classof  a[j] ) == BitmapTexture then
		(
			s = a[j].FileName
			s = fileNameFromPath s
			a[j].FileName = ""
			a[j].FileName = s
		)
	)
)