function individual_export =
(
    objs = $objects
    for i=1 to objs.count do 
    (
        local outputPath = "F:\_px\3dWork\ForTS\LowPolyStyle\WorldPeople\upload_400FixedPoses\max\separated_500files\\"
        local filename = objs[i].name + ".fbx"
        select objs[i]
        objs[i].position = [0,0,0]
        exportFile (outputpath+filename) #noPrompt selectedOnly:true
        --      saveNodes objs[i] (outputpath+filename) quiet:true
    )
)
individual_export()