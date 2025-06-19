fn PackGlossIntoMetallicAlpha metalPath glossPath outputPath = (
    metalBmp = openBitmap metalPath
    glossBmp = openBitmap glossPath

    width = metalBmp.width
    height = metalBmp.height

    -- Create output RGBA bitmap
    resultBmp = bitmap width height color:(color 0 0 0) filename:outputPath

    for y = 0 to height - 1 do (
        for x = 0 to width - 1 do (
            c = getPixels metalBmp [x, y] 1
            g = getPixels glossBmp [x, y] 1

            if c.count > 0 and g.count > 0 do (
                rgb = c[1]
                glossGray = (g[1].r + g[1].g + g[1].b) / 3

                setPixels resultBmp [x, y] #(color rgb.r rgb.g rgb.b glossGray )
            )
        )
    )

	display resultBmp
    save resultBmp
    close metalBmp
    close glossBmp
    close resultBmp
)

-- Example usage:
PackGlossIntoMetallicAlpha "military_props_metal.png" "military_props_gloss.png" "f://resultxx.png"
MessageBox "wait"