-- Invert the X value of selected vertices from Editable Poly object.

in coordsys local (        
    local verts = polyop.getVertSelection $
    verts = verts as array
    local posis = #()
    posis.count = verts.count
    for i=1 to verts.count do 
    (
        local v = polyOp.getVert $ verts[i]
        v.x = -v.x
        posis[i] = v
    )
    polyOp.setVert $ verts posis 
)