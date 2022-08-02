-- Export all .max files in folder to glTF using Babylon Plugin:
-- URL 3ds Max plugin installer: https://github.com/BabylonJS/Exporters/releases

sourcePath = @"F:\_px\3D\_sell\LowPolyStyle\WorldPeople\scenes\anipack\_upload\max\"
outputPath = @"F:\_px\3D\_sell\LowPolyStyle\WorldPeople\scenes\anipack\_upload\glTF\"

maxNames = getFiles (sourcePath + "*.max")

Assembly = dotNetClass "System.Reflection.Assembly"
try (
	Assembly.loadfrom @"C:\Program Files\Autodesk\3ds Max 2019\bin\assemblies\Max2Babylon.dll"
) catch (
	messageBox "ERROR!: Babylon Exporter plugin loading failded!"
)

maxScriptManager = dotNetObject "Max2Babylon.MaxScriptManager"

param = maxScriptManager.InitParameters ""

for fname in maxNames do
(
	if (loadMaxFile fname quiet:true) then 
	(
			local outName = (getFilenameFile fname)
			outName = outName +".gltf"
			outName = outPutPath + outName
			param.outputPath = outName
			param.outputFormat = "gltf"
			param.exportAnimations = true
			param.exportSkins = true
			
			
			maxScriptManager.Export param
	)
)