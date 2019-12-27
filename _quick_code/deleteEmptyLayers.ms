--delete empty layers

function clean=
(
    local n = LayerManager.count
    local layers = #()
    --layer 0 is default
    for i = 1 to n-1 do 
    (
        layers[i] = LayerManager.getLayer i        
        --i can't delete here its complicated... list shrinks... etc. 
    )
    -- second pass, delete 
    for i = 1 to n - 1 do  
    (
        LayerManager.deleteLayerByName layers[i].name        
    )        
)
clean()