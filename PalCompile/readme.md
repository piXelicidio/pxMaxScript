# PalCompile - 3ds Max Palette Compilation Toolkit

**PalCompile** is a MaxScript toolkit for Autodesk 3ds Max that helps you extract, analyze, reduce, and repack texture palette data from polygon sections across multiple models and scenes. It is especially useful for workflows where you want to optimize or remap UVs and textures for stylized or low-poly assets.

---

## Features

- **Export UV and Texel Data:**  
  Export per-face UV and color information for each named face selection set (section) in your Editable_Poly objects.

- **Process and Analyze:**  
  Load exported data, group by section, and analyze face/color/UV usage across your assets.

- **Color Similarity Reduction:**  
  Merge similar colors within sections to reduce palette size and optimize texture usage.

- **Palette Packing:**  
  Build a new packed palette texture, assigning new UVs to each face/section, and visualize the result.

- **Export Repacked UVs:**  
  Write updated UVs back to `.txt` files in a `.repacked` subfolder, preserving the original file structure.

- **Apply Repacked UVs:**  
  Automatically apply the new UVs to your scene objects, updating all faces in all sections.

---

## How to Use

### 1. **Export UV Sections**
- Select your Editable_Poly objects (or leave nothing selected to process all).
- Make sure each object has named face selection sets (sections).
- Click **Export UV sections**.  
  This creates `.txt` files for each section in the format:  
  `scene@object@section.txt`  
  Each line:  
  ```
  face [uv] [color]
  ```

### 2. **Process Files**
- Set your wildcard (default: `*.txt`) if needed.
- Click **Process files...**  
  This loads all exported files and prepares the data for reduction and packing.

### 3. **Reduce Similarity (Optional)**
- Set a color similarity threshold.
- Optionally, restrict reduction to a single section.
- Click **Similarity reduction...**  
  This merges similar colors to optimize your palette.

### 4. **Build Packed Texture**
- Click **Build Packed Texture**.  
  This sorts and packs all sections into a new texture, assigning new UVs.

### 5. **Export Repacked UVs**
- Click **Export Repacked UVs...**  
  This writes new `.txt` files with updated UVs to a `.repacked` subfolder.

### 6. **Apply Repacked UVs**
- Select your objects (or leave nothing selected to process all).
- Click **Apply Repacked UVs**.  
  This updates all faces in your Editable_Poly objects with the new UVs from the `.repacked` files.

---

## File Format

- **Exported/Processed Files:**  
  `scene@object@section.txt`  
  Each line:  
  ```
  face [uv] [color]
  ```
- **Repacked Files:**  
  Same naming, but only `face [uv]` per line, written to `.repacked` subfolder.

---

## Requirements

- Autodesk 3ds Max (tested on 2020+)
- Editable_Poly objects with named face selection sets
- Materials with supported diffuse maps

---

## Notes & Disclaimer

- The tool does **not** overwrite your original exported files; repacked UVs are written to a `.repacked` subfolder.
- **However, the "Apply Repacked UVs" operation is destructive:**  
  It will overwrite the UVs of faces in your scene objects.  
  **Always backup your scene files before using this tool.**
- This script is provided **without any warranty**. Use at your own risk!
- UVs are automatically flipped to match 3ds Max's coordinate conventions.
- All operations except "Apply Repacked UVs" are non-destructive to your original scene.

