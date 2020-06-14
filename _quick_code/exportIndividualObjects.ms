
function individual_export =
(
    objs = $objects
    ext = ".obj"
    for i=1 to objs.count do 
    (
        local outputPath = "F:\_px\3dWork\ForTS\LowPolyStyle\props_indoor\_upload\kitchen\obj_sep\\"
        local filename = objs[i].name + ext        
        select objs[i]
        objs[i].position = [0,0,0]
        if ext == ".max" then 
        (
           saveNodes objs[i] (outputpath+filename) quiet:true
        ) else 
        (
            exportFile (outputpath+filename) #noPrompt selectedOnly:true
        )
        
    )
)
individual_export()