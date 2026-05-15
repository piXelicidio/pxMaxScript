using System;
using System.Drawing;
using System.Collections.Generic;
using System.Diagnostics;

namespace dotnet_polypaint
{
    public class PolypaintHelpers
    {
        private const int ColorMergeThresholdSquared = 5;

        private byte[] resultBitmapPixels;
        private int resultBitmapWidth;
        private int resultBitmapHeight;
        private int resultBitmapCellSize;
        private int resultBitmapColumns;
        private float[] resultFaceUVs;

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

        public float[] GetResultFaceUVs()
        {
            return resultFaceUVs;
        }

        public string ProcessLowPolyPixels(int width, int height, byte[] pixels, float[] uvData, int[][] mapFaces)
        {
            resultBitmapPixels = null;
            resultBitmapWidth = 0;
            resultBitmapHeight = 0;
            resultBitmapCellSize = 0;
            resultBitmapColumns = 0;
            resultFaceUVs = null;

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

            long stageStartMs = stopwatch.ElapsedMilliseconds;
            PointF[][] facePixelPolygons = BuildFacePixelPolygons(uvData, uvPoints, mapFaces, width, height, sb);
            long buildFacePolygonsMs = stopwatch.ElapsedMilliseconds - stageStartMs;
            if (facePixelPolygons == null)
            {
                sb.AppendLine("[PolypaintHelpers] ---------------------------------");
                return sb.ToString();
            }

            int[] averageColors = new int[facesCount * 3];

            stageStartMs = stopwatch.ElapsedMilliseconds;
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
            }
            long scanFaceTexelsMs = stopwatch.ElapsedMilliseconds - stageStartMs;

            stageStartMs = stopwatch.ElapsedMilliseconds;
            List<ColorGroup> colorGroups = ReduceColorGroups(averageColors, facesCount, sb);
            long reduceColorGroupsMs = stopwatch.ElapsedMilliseconds - stageStartMs;

            stageStartMs = stopwatch.ElapsedMilliseconds;
            BuildResultBitmap(colorGroups, facesCount);
            long buildResultBitmapMs = stopwatch.ElapsedMilliseconds - stageStartMs;
            sb.AppendLine(string.Format("[PolypaintHelpers] Result Bitmap: {0}x{1}, columns={2}, cell={3}", resultBitmapWidth, resultBitmapHeight, resultBitmapColumns, resultBitmapCellSize));

            stopwatch.Stop();
            sb.AppendLine(string.Format("[PolypaintHelpers] Build Face Pixel Polygons Time: {0} ms", buildFacePolygonsMs));
            sb.AppendLine(string.Format("[PolypaintHelpers] Scan Face Texels Time: {0} ms", scanFaceTexelsMs));
            sb.AppendLine(string.Format("[PolypaintHelpers] Reduce Color Groups Time: {0} ms", reduceColorGroupsMs));
            sb.AppendLine(string.Format("[PolypaintHelpers] Build Result Bitmap/UVs Time: {0} ms", buildResultBitmapMs));
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

        private static List<ColorGroup> ReduceColorGroups(int[] averageColors, int facesCount, System.Text.StringBuilder sb)
        {
            List<ColorGroup> groups = new List<ColorGroup>();

            for (int faceIndex = 0; faceIndex < facesCount; faceIndex++)
            {
                int colorOffset = faceIndex * 3;
                ColorGroup group = new ColorGroup(averageColors[colorOffset], averageColors[colorOffset + 1], averageColors[colorOffset + 2]);
                group.Faces.Add(faceIndex);
                groups.Add(group);
            }

            int mergeCount = 0;
            while (MergeClosestGroupPair(groups))
            {
                mergeCount++;
            }

            sb.AppendLine(string.Format("[PolypaintHelpers] Color Groups: {0} -> {1}, merges={2}, threshold={3}", facesCount, groups.Count, mergeCount, ColorMergeThresholdSquared));
            return groups;
        }

        private static bool MergeClosestGroupPair(List<ColorGroup> groups)
        {
            int bestA = -1;
            int bestB = -1;
            int bestDistanceSquared = ColorMergeThresholdSquared + 1;

            for (int a = 0; a < groups.Count - 1; a++)
            {
                for (int b = a + 1; b < groups.Count; b++)
                {
                    int distanceSquared = ColorDistanceSquared(groups[a], groups[b]);
                    if (distanceSquared < bestDistanceSquared)
                    {
                        bestDistanceSquared = distanceSquared;
                        bestA = a;
                        bestB = b;
                    }
                }
            }

            if (bestA < 0 || bestDistanceSquared > ColorMergeThresholdSquared)
            {
                return false;
            }

            MergeGroups(groups, bestA, bestB);
            return true;
        }

        private static int ColorDistanceSquared(ColorGroup a, ColorGroup b)
        {
            int dr = a.R - b.R;
            int dg = a.G - b.G;
            int db = a.B - b.B;
            return dr * dr + dg * dg + db * db;
        }

        private static void MergeGroups(List<ColorGroup> groups, int indexA, int indexB)
        {
            ColorGroup a = groups[indexA];
            ColorGroup b = groups[indexB];
            int faceCountA = a.Faces.Count;
            int faceCountB = b.Faces.Count;
            int mergedFaceCount = faceCountA + faceCountB;

            a.R = ((a.R * faceCountA) + (b.R * faceCountB)) / mergedFaceCount;
            a.G = ((a.G * faceCountA) + (b.G * faceCountB)) / mergedFaceCount;
            a.B = ((a.B * faceCountA) + (b.B * faceCountB)) / mergedFaceCount;

            for (int i = 0; i < b.Faces.Count; i++)
            {
                a.Faces.Add(b.Faces[i]);
            }

            groups.RemoveAt(indexB);
        }

        private void BuildResultBitmap(List<ColorGroup> colorGroups, int facesCount)
        {
            int colorCount = colorGroups.Count;
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
            resultFaceUVs = new float[facesCount * 2];

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
                ColorGroup group = colorGroups[colorIndex];
                float u = ((float)startX + ((float)cellSize * 0.5f)) / (float)resultBitmapWidth;
                float v = 1.0f - (((float)startY + ((float)cellSize * 0.5f)) / (float)resultBitmapHeight);

                // Apply inverse 2.2 gamma to cancel out 3ds Max's double-brightening
                byte finalR = (byte)Math.Min(255, Math.Max(0, Math.Pow(group.R / 255.0, 2.2) * 255.0));
                byte finalG = (byte)Math.Min(255, Math.Max(0, Math.Pow(group.G / 255.0, 2.2) * 255.0));
                byte finalB = (byte)Math.Min(255, Math.Max(0, Math.Pow(group.B / 255.0, 2.2) * 255.0));
                FillResultSquare(
                    startX,
                    startY,
                    cellSize,
                    finalR,
                    finalG,
                    finalB
                );

                for (int i = 0; i < group.Faces.Count; i++)
                {
                    int faceIndex = group.Faces[i];
                    int uvOffset = faceIndex * 2;
                    resultFaceUVs[uvOffset] = u;
                    resultFaceUVs[uvOffset + 1] = v;
                }
            }
        }

        private class ColorGroup
        {
            public int R;
            public int G;
            public int B;
            public List<int> Faces;

            public ColorGroup(int r, int g, int b)
            {
                R = r;
                G = g;
                B = b;
                Faces = new List<int>();
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
