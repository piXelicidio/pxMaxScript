using System;
using System.Drawing;
using System.Diagnostics;

namespace dotnet_polypaint
{
    public class PolypaintHelpers
    {
        private byte[] resultBitmapPixels;
        private int resultBitmapWidth;
        private int resultBitmapHeight;
        private int resultBitmapCellSize;
        private int resultBitmapColumns;

        public int sum(int a, int b)
        {
            return a * 2 + b * 2;
        }

        public byte[] GetResultBitmapPixels()
        {
            return resultBitmapPixels;
        }

        public int GetResultBitmapWidth()
        {
            return resultBitmapWidth;
        }

        public int GetResultBitmapHeight()
        {
            return resultBitmapHeight;
        }

        public int GetResultBitmapCellSize()
        {
            return resultBitmapCellSize;
        }

        public int GetResultBitmapColumns()
        {
            return resultBitmapColumns;
        }

        public string ProcessLowPolyPixels(int width, int height, byte[] pixels, float[] uvData, int[][] mapFaces)
        {
            resultBitmapPixels = null;
            resultBitmapWidth = 0;
            resultBitmapHeight = 0;
            resultBitmapCellSize = 0;
            resultBitmapColumns = 0;

            var sb = new System.Text.StringBuilder();
            sb.AppendLine("[PolypaintHelpers] --- Processing LowPoly Data ---");
            sb.AppendLine(string.Format("[PolypaintHelpers] Bitmap: {0}x{1}", width, height));

            if (width <= 0 || height <= 0)
            {
                sb.AppendLine("[PolypaintHelpers] ERROR: bitmap dimensions must be greater than zero.");
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            if (pixels == null)
            {
                sb.AppendLine("[PolypaintHelpers] ERROR: pixels is null.");
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            int expectedPixelBytes = width * height * 4;
            if (pixels.Length != expectedPixelBytes)
            {
                sb.AppendLine(string.Format("[PolypaintHelpers] ERROR: pixels length is {0}, expected {1}.", pixels.Length, expectedPixelBytes));
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

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

            if (facesCount <= 0)
            {
                sb.AppendLine("[PolypaintHelpers] ERROR: mapFaces has no faces.");
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            sb.AppendLine(string.Format("[PolypaintHelpers] Total UV Points: {0}", uvPoints));
            sb.AppendLine(string.Format("[PolypaintHelpers] Total Map Faces: {0}", facesCount));

            Stopwatch stopwatch = Stopwatch.StartNew();

            PointF[][] facePixelPolygons = BuildFacePixelPolygons(uvData, uvPoints, mapFaces, width, height, sb);
            if (facePixelPolygons == null)
            {
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            int[] averageColors = new int[facesCount * 3];

            for (int faceIndex = 0; faceIndex < facePixelPolygons.Length; faceIndex++)
            {
                int averageR;
                int averageG;
                int averageB;
                int pixelCount;
                bool gotPixels = ScanFaceTexelsAverage(pixels, width, height, facePixelPolygons[faceIndex], out averageR, out averageG, out averageB, out pixelCount);

                int colorOffset = faceIndex * 3;
                averageColors[colorOffset] = averageR;
                averageColors[colorOffset + 1] = averageG;
                averageColors[colorOffset + 2] = averageB;

                if (gotPixels)
                {
                    sb.AppendLine(string.Format("[PolypaintHelpers] Face {0}: pixels={1}, average=({2}, {3}, {4})", faceIndex, pixelCount, averageR, averageG, averageB));
                }
                else
                {
                    sb.AppendLine(string.Format("[PolypaintHelpers] Face {0}: pixels=0, center=({1}, {2}, {3})", faceIndex, averageR, averageG, averageB));
                }
            }

            BuildResultBitmap(averageColors, facesCount);
            sb.AppendLine(string.Format("[PolypaintHelpers] Result Bitmap: {0}x{1}, columns={2}, cell={3}", resultBitmapWidth, resultBitmapHeight, resultBitmapColumns, resultBitmapCellSize));

            stopwatch.Stop();
            sb.AppendLine(string.Format("[PolypaintHelpers] Process Time: {0} ms", stopwatch.ElapsedMilliseconds));
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

        private void BuildResultBitmap(int[] averageColors, int colorCount)
        {
            int bitmapSize = 256;
            int columns = 1;
            int cellSize = bitmapSize;

            while (true)
            {
                columns = (int)Math.Ceiling(Math.Sqrt(colorCount));
                cellSize = bitmapSize / columns;
                if (cellSize > 8)
                {
                    break;
                }

                bitmapSize *= 2;
            }

            resultBitmapWidth = bitmapSize;
            resultBitmapHeight = bitmapSize;
            resultBitmapCellSize = cellSize;
            resultBitmapColumns = columns;
            resultBitmapPixels = new byte[bitmapSize * bitmapSize * 4];

            for (int i = 0; i < resultBitmapPixels.Length; i += 4)
            {
                resultBitmapPixels[i] = 0;
                resultBitmapPixels[i + 1] = 0;
                resultBitmapPixels[i + 2] = 0;
                resultBitmapPixels[i + 3] = 255;
            }

            for (int colorIndex = 0; colorIndex < colorCount; colorIndex++)
            {
                int gridX = colorIndex % columns;
                int gridY = colorIndex / columns;
                int startX = gridX * cellSize;
                int startY = gridY * cellSize;
                int colorOffset = colorIndex * 3;

                FillResultSquare(
                    startX,
                    startY,
                    cellSize,
                    (byte)averageColors[colorOffset],
                    (byte)averageColors[colorOffset + 1],
                    (byte)averageColors[colorOffset + 2]
                );
            }
        }

        private void FillResultSquare(int startX, int startY, int size, byte r, byte g, byte b)
        {
            for (int y = startY; y < startY + size; y++)
            {
                for (int x = startX; x < startX + size; x++)
                {
                    int pixelOffset = (y * resultBitmapWidth + x) * 4;
                    resultBitmapPixels[pixelOffset] = r;
                    resultBitmapPixels[pixelOffset + 1] = g;
                    resultBitmapPixels[pixelOffset + 2] = b;
                    resultBitmapPixels[pixelOffset + 3] = 255;
                }
            }
        }

        private static bool ScanFaceTexelsAverage(byte[] pixels, int width, int height, PointF[] face, out int averageR, out int averageG, out int averageB, out int pixelCount)
        {
            int minX = ClampToBitmap((int)Math.Floor(GetMinX(face)), width);
            int maxX = ClampToBitmap((int)Math.Ceiling(GetMaxX(face)), width);
            int minY = ClampToBitmap((int)Math.Floor(GetMinY(face)), height);
            int maxY = ClampToBitmap((int)Math.Ceiling(GetMaxY(face)), height);

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
                        int pixelOffset = (y * width + x) * 4;
                        totalR += pixels[pixelOffset];
                        totalG += pixels[pixelOffset + 1];
                        totalB += pixels[pixelOffset + 2];
                        pixelCount++;
                    }
                }
            }

            if (pixelCount == 0)
            {
                SampleFaceCenter(pixels, width, height, face, out averageR, out averageG, out averageB);
                return false;
            }

            averageR = (int)(totalR / pixelCount);
            averageG = (int)(totalG / pixelCount);
            averageB = (int)(totalB / pixelCount);

            return true;
        }

        private static void SampleFaceCenter(byte[] pixels, int width, int height, PointF[] face, out int r, out int g, out int b)
        {
            float centerX = 0.0f;
            float centerY = 0.0f;

            for (int i = 0; i < face.Length; i++)
            {
                centerX += face[i].X;
                centerY += face[i].Y;
            }

            centerX /= face.Length;
            centerY /= face.Length;

            int x = ClampToBitmap((int)Math.Floor(centerX), width);
            int y = ClampToBitmap((int)Math.Floor(centerY), height);
            int pixelOffset = (y * width + x) * 4;

            r = pixels[pixelOffset];
            g = pixels[pixelOffset + 1];
            b = pixels[pixelOffset + 2];
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
