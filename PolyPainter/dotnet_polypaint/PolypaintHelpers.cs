using System;
using System.Drawing;
using System.Drawing.Imaging;

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
                ImageFormat imageFormat;
                Bitmap bitmap;
                using (Bitmap sourceBitmap = new Bitmap(imagePath))
                {
                    imageFormat = sourceBitmap.RawFormat;
                    bitmap = new Bitmap(sourceBitmap);
                }

                using (bitmap)
                {
                    sb.AppendLine(string.Format("[PolypaintHelpers] Loaded Bitmap: {0}x{1}", bitmap.Width, bitmap.Height));

                    PointF[][] facePixelPolygons = BuildFacePixelPolygons(uvData, uvPoints, mapFaces, bitmap.Width, bitmap.Height, sb);
                    if (facePixelPolygons == null)
                    {
                        sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                        return sb.ToString();
                    }

                    int facesToDebug = Math.Min(facePixelPolygons.Length, 3);
                    for (int faceIndex = 0; faceIndex < facesToDebug; faceIndex++)
                    {
                        Color averageColor;
                        int pixelCount;
                        bool gotPixels = ScanFaceTexelsAverageAndPink(bitmap, facePixelPolygons[faceIndex], out averageColor, out pixelCount);

                        if (gotPixels)
                        {
                            sb.AppendLine(string.Format("[PolypaintHelpers] Face {0}: pixels={1}, average=({2}, {3}, {4})", faceIndex, pixelCount, averageColor.R, averageColor.G, averageColor.B));
                        }
                        else
                        {
                            sb.AppendLine(string.Format("[PolypaintHelpers] Face {0}: pixels=0", faceIndex));
                        }
                    }

                    bitmap.Save(imagePath, imageFormat);
                    sb.AppendLine(string.Format("[PolypaintHelpers] Saved pink debug texture: {0}", imagePath));
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

        private static PointF[][] BuildFacePixelPolygons(float[] uvData, int uvPoints, int[][] mapFaces, int bitmapWidth, int bitmapHeight, System.Text.StringBuilder sb)
        {
            PointF[][] facePixelPolygons = new PointF[mapFaces.Length][];

            for (int faceIndex = 0; faceIndex < mapFaces.Length; faceIndex++)
            {
                int[] face = mapFaces[faceIndex];
                if (face == null)
                {
                    sb.AppendLine(string.Format("[PolypaintHelpers] ERROR: mapFaces[{0}] is null.", faceIndex));
                    return null;
                }

                if (face.Length == 0)
                {
                    sb.AppendLine(string.Format("[PolypaintHelpers] ERROR: mapFaces[{0}] has no vertices.", faceIndex));
                    return null;
                }

                PointF[] polygon = new PointF[face.Length];
                for (int vertexIndex = 0; vertexIndex < face.Length; vertexIndex++)
                {
                    int uvIndex = face[vertexIndex];
                    if (uvIndex < 0 || uvIndex >= uvPoints)
                    {
                        sb.AppendLine(string.Format("[PolypaintHelpers] ERROR: mapFaces[{0}][{1}] references uv index {2}, but valid range is 0 to {3}.", faceIndex, vertexIndex, uvIndex, uvPoints - 1));
                        return null;
                    }

                    int uvOffset = uvIndex * 2;
                    float u = uvData[uvOffset];
                    float v = uvData[uvOffset + 1];
                    float x = u * bitmapWidth;
                    float y = (1.0f - v) * bitmapHeight;

                    polygon[vertexIndex] = new PointF(x, y);
                }

                facePixelPolygons[faceIndex] = polygon;
            }

            return facePixelPolygons;
        }

        private static bool ScanFaceTexelsAverageAndPink(Bitmap bitmap, PointF[] face, out Color averageColor, out int pixelCount)
        {
            int minX = ClampToBitmap((int)Math.Floor(GetMinX(face)), bitmap.Width);
            int maxX = ClampToBitmap((int)Math.Ceiling(GetMaxX(face)), bitmap.Width);
            int minY = ClampToBitmap((int)Math.Floor(GetMinY(face)), bitmap.Height);
            int maxY = ClampToBitmap((int)Math.Ceiling(GetMaxY(face)), bitmap.Height);

            long totalR = 0;
            long totalG = 0;
            long totalB = 0;
            pixelCount = 0;

            for (int y = minY; y <= maxY; y++)
            {
                for (int x = minX; x <= maxX; x++)
                {
                    if (PointInsidePolygon(x + 0.5f, y + 0.5f, face))
                    {
                        Color pixel = bitmap.GetPixel(x, y);
                        totalR += pixel.R;
                        totalG += pixel.G;
                        totalB += pixel.B;
                        pixelCount++;

                        bitmap.SetPixel(x, y, Color.FromArgb(255, 255, 0, 255));
                    }
                }
            }

            if (pixelCount == 0)
            {
                averageColor = Color.Empty;
                return false;
            }

            averageColor = Color.FromArgb(
                (int)(totalR / pixelCount),
                (int)(totalG / pixelCount),
                (int)(totalB / pixelCount)
            );
            return true;
        }

        private static bool PointInsidePolygon(float x, float y, PointF[] polygon)
        {
            bool inside = false;
            int previous = polygon.Length - 1;

            for (int current = 0; current < polygon.Length; current++)
            {
                PointF a = polygon[current];
                PointF b = polygon[previous];

                if (((a.Y > y) != (b.Y > y)) &&
                    (x < (b.X - a.X) * (y - a.Y) / (b.Y - a.Y) + a.X))
                {
                    inside = !inside;
                }

                previous = current;
            }

            return inside;
        }

        private static int ClampToBitmap(int value, int size)
        {
            if (value < 0)
            {
                return 0;
            }

            if (value >= size)
            {
                return size - 1;
            }

            return value;
        }

        private static float GetMinX(PointF[] polygon)
        {
            float value = polygon[0].X;
            for (int i = 1; i < polygon.Length; i++)
            {
                value = Math.Min(value, polygon[i].X);
            }
            return value;
        }

        private static float GetMaxX(PointF[] polygon)
        {
            float value = polygon[0].X;
            for (int i = 1; i < polygon.Length; i++)
            {
                value = Math.Max(value, polygon[i].X);
            }
            return value;
        }

        private static float GetMinY(PointF[] polygon)
        {
            float value = polygon[0].Y;
            for (int i = 1; i < polygon.Length; i++)
            {
                value = Math.Min(value, polygon[i].Y);
            }
            return value;
        }

        private static float GetMaxY(PointF[] polygon)
        {
            float value = polygon[0].Y;
            for (int i = 1; i < polygon.Length; i++)
            {
                value = Math.Max(value, polygon[i].Y);
            }
            return value;
        }
    }
}
