using System;
using System.Drawing;

namespace dotnet_polypaint
{
    public class PolypaintHelpers
    {
        public int sum(int a, int b)
        {
            return a * 2 + b * 2;
        }

        public string TestLoadBitmap(string filePath)
        {
            try
            {
                using (Bitmap bmp = new Bitmap(filePath))
                {
                    Color firstPixel = bmp.GetPixel(0, 0);
                    return string.Format("Success! Image is {0}x{1}. Pixel(0,0) is R:{2} G:{3} B:{4}", bmp.Width, bmp.Height, firstPixel.R, firstPixel.G, firstPixel.B);
                }
            }
            catch (Exception ex)
            {
                return "Error loading bitmap: " + ex.Message;
            }
        }

        public string ProcessLowPoly(string imagePath, float[] uvData, int[][] mapFaces)
        {
            var sb = new System.Text.StringBuilder();
            sb.AppendLine("[PolypaintHelpers] --- Processing LowPoly Data ---");
            sb.AppendLine(string.Format("[PolypaintHelpers] Image Path: {0}", imagePath));

            if (uvData == null)
            {
                sb.AppendLine("[PolypaintHelpers] ERROR: uvData is null.");
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            if (mapFaces == null)
            {
                sb.AppendLine("[PolypaintHelpers] ERROR: mapFaces is null.");
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            if ((uvData.Length % 2) != 0)
            {
                sb.AppendLine("[PolypaintHelpers] ERROR: uvData length must be even. Expected [u0, v0, u1, v1, ...].");
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            int uvPoints = uvData.Length / 2;
            int facesCount = mapFaces.Length;

            sb.AppendLine(string.Format("[PolypaintHelpers] Total UV Points: {0}", uvPoints));
            sb.AppendLine(string.Format("[PolypaintHelpers] Total Map Faces: {0}", facesCount));

            try
            {
                using (Bitmap bitmap = new Bitmap(imagePath))
                {
                    sb.AppendLine(string.Format("[PolypaintHelpers] Loaded Bitmap: {0}x{1}", bitmap.Width, bitmap.Height));

                    PointF[][] facePixelPolygons = new PointF[facesCount][];

                    for (int faceIndex = 0; faceIndex < facesCount; faceIndex++)
                    {
                        int[] face = mapFaces[faceIndex];
                        if (face == null)
                        {
                            sb.AppendLine(string.Format("[PolypaintHelpers] ERROR: mapFaces[{0}] is null.", faceIndex));
                            sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                            return sb.ToString();
                        }

                        if (face.Length == 0)
                        {
                            sb.AppendLine(string.Format("[PolypaintHelpers] ERROR: mapFaces[{0}] has no vertices.", faceIndex));
                            sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                            return sb.ToString();
                        }

                        PointF[] polygon = new PointF[face.Length];
                        for (int vertexIndex = 0; vertexIndex < face.Length; vertexIndex++)
                        {
                            int uvIndex = face[vertexIndex];
                            if (uvIndex < 0 || uvIndex >= uvPoints)
                            {
                                sb.AppendLine(string.Format("[PolypaintHelpers] ERROR: mapFaces[{0}][{1}] references uv index {2}, but valid range is 0 to {3}.", faceIndex, vertexIndex, uvIndex, uvPoints - 1));
                                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                                return sb.ToString();
                            }

                            int uvOffset = uvIndex * 2;
                            float u = uvData[uvOffset];
                            float v = uvData[uvOffset + 1];
                            float x = u * bitmap.Width;
                            float y = (1.0f - v) * bitmap.Height;

                            polygon[vertexIndex] = new PointF(x, y);
                        }

                        facePixelPolygons[faceIndex] = polygon;
                    }
                }
            }
            catch (Exception ex)
            {
                sb.AppendLine("[PolypaintHelpers] ERROR: Could not load or process bitmap: " + ex.Message);
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            sb.AppendLine("[PolypaintHelpers] ---------------------------------");

            return sb.ToString();
        }
    }
}
