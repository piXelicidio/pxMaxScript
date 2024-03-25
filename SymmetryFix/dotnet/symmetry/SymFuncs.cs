using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Numerics;
using System.Linq;
namespace Symmetry
{
    public static class Functions
    {
        public static TResult FindPairs(float[][] vertPositions, int[][] vertsInfo_LinkedTo)
        {            
            var vertsInfo_RightSide = new bool[vertPositions.Length];
            var vertsInfo_PairedWith = new int[vertPositions.Length];
            var positiveVerts = new List<int>();
            var negativeVerts = new List<int>();
            var tolerance = 0.005f;


            //var UnpairedSet = new BitArray(vertPositions.Length);
            //UnpairedSet.SetAll(true);
            var UnpairedSet = new HashSet<int>(Enumerable.Range(0, vertPositions.Length));
            //Debug.WriteLine("FindPairs v1.1");
            // initializing verts information
            var sw = Stopwatch.StartNew();
            for (int i = 0; i < vertPositions.Length; i++)
            {
                var v = vertPositions[i];
                vertsInfo_PairedWith[i] = -1; //undefined pair
                if (Vec3.X(v) >= 0)
                {
                    vertsInfo_RightSide[i] = true;
                    positiveVerts.Add(i);
                } else
                {
                    negativeVerts.Add(i);
                }

                //idexes comming from MaxScript are 1-based, fixing...
                for (int j = 0; j < vertsInfo_LinkedTo[i].Length; j++)
                {
                    vertsInfo_LinkedTo[i][j]--;                                      
                }

                //those in the center (close to x = 0) paired with themselves
                if (Math.Abs(Vec3.X(v)) <= tolerance)
                {
                    vertsInfo_PairedWith[i] = i;
                    UnpairedSet.Remove(i);
                }                

            }
            Debug.WriteLine($"build-10\nInitializing {vertPositions.Length} verts: {sw.ElapsedMilliseconds}ms");
            
            sw.Restart();
            //finding pairs by position
            for (int i = 0; i < positiveVerts.Count; i++)
            {
                var v1 = vertPositions[positiveVerts[i]];
                for (int j = 0; j < negativeVerts.Count; j++)
                {
                    var v2 = vertPositions[negativeVerts[j]];
                    if (Math.Abs(- v2[0] - v1[0]) < tolerance &&
                        Math.Abs(v2[1] - v1[1]) < tolerance &&
                        Math.Abs(v2[2] - v1[2]) < tolerance)
                    {
                        //building relationships
                        vertsInfo_PairedWith[positiveVerts[i]] = negativeVerts[j];
                        vertsInfo_PairedWith[negativeVerts[j]] = positiveVerts[i];
                        UnpairedSet.Remove(positiveVerts[i]);
                        UnpairedSet.Remove(negativeVerts[j]);
                    }
                }
            }
            Debug.WriteLine($"Pairs by position: {sw.ElapsedMilliseconds}ms");
            sw.Restart();

            //incoming cool stuff ------------------------- PAIR BY EDGE CONNECTION ANALYSIS


            // ResultList cointains the unpaired vertices

            int FoundNewPairs;
            do
            {
                var UnpairedList = UnpairedSet.ToArray(); 
                FoundNewPairs = 0;
                for (int i = 0; i < UnpairedList.Length; i++)
                {
                    var RIndex = UnpairedList[i];
                    var RightSymLinks = new HashSet<int>();
                    int RightUnpairedLinks = 0;
                    foreach (var k in vertsInfo_LinkedTo[RIndex])
                    {
                        if (vertsInfo_PairedWith[k] == -1)
                            RightUnpairedLinks++;
                        else
                            RightSymLinks.Add(k);
                    }

                    if (vertsInfo_PairedWith[RIndex] == -1 && RightSymLinks.Count > 0) 
                    {
                        int MyCandidate = -1;
                        int MyCandidateNum = 0;
                        for (int j = 0; j < UnpairedList.Length; j++)
                        {
                            var LIndex = UnpairedList[j];                            
                            var LeftSymLinks = new HashSet<int>();                            
                            int LeftUnpairedLinks = 0;
                            //collect both sides pairs                           
                            foreach (var k in vertsInfo_LinkedTo[LIndex])
                            {
                                if (vertsInfo_PairedWith[k] == -1)
                                    LeftUnpairedLinks++;
                                else
                                    LeftSymLinks.Add(vertsInfo_PairedWith[k]);
                            }

                            //evaluate candidate
                            if (LeftSymLinks.Count > 0)
                            {
                                if (RightSymLinks.SetEquals(LeftSymLinks))
                                {
                                    if (RightUnpairedLinks == LeftUnpairedLinks)
                                    {
                                        //this is a good candidate
                                        MyCandidateNum++;
                                        if (MyCandidate == -1)
                                        {
                                            //is first one, hope only 
                                            MyCandidate = LIndex;
                                            
                                        }
                                    }
                                }
                            }
                        }

                        //if one and only one then is good to go, else... think later                        
                        if (MyCandidateNum == 1)
                        {

                            //we can pair vert I with vert MyCandidate
                            vertsInfo_PairedWith[RIndex] = MyCandidate;
                            vertsInfo_PairedWith[MyCandidate] = RIndex;
                            FoundNewPairs++;
                            UnpairedSet.Remove(RIndex);
                            UnpairedSet.Remove(MyCandidate);
                        }
                    }
                }
            } while (FoundNewPairs > 0);

            Debug.WriteLine($"Pairing by edges: {sw.ElapsedMilliseconds}ms");
            sw.Restart();

            //return ToMxsArray(Result);
            var res = new TResult();
            res.unpaired = ToMxsArray(UnpairedSet);
            res.rightSide = vertsInfo_RightSide;
            res.pairedWith = vertsInfo_PairedWith; //this is 0 based, remember add 1 in MaxScript.
            Debug.WriteLine($"Preparing result: {sw.ElapsedMilliseconds}ms");
            return res;
        }

        public struct TResult
        {
            public int[] unpaired;
            public bool[] rightSide;
            public int[] pairedWith;
        }
        
        private static int[] ToMxsArray(BitArray bits)
        {
            var list = new List<int>();
            for (int i = 0; i < bits.Length; i++)
            {
                if (bits[i]) list.Add(i + 1); //'cause MaxScript arrays indexes are 1-based;		
            }
            return list.ToArray();
        }

        private static int[] ToMxsArray(HashSet<int> ints)
        {
            var list = ints.ToArray();
            for (int i = 0; list.Length > i; i++) list[i]++;
            return list;
        }

        private static int[] ToArray(BitArray bits)
        {
            var list = new List<int>();
            for (int i = 0; i < bits.Length; i++)
            {
                if (bits[i]) list.Add(i); 
            }
            return list.ToArray();
        }
    }

    internal static class Vec3
    {
        // Get the X component of a vector
        public static float X(float[] vector)
        {
            return vector[0];
        }

        // Get the Y component of a vector
        public static float Y(float[] vector)
        {
            return vector[1];
        }

        // Get the Z component of a vector
        public static float Z(float[] vector)
        {
            return vector[2];
        }

        //distance between two vectors
        public static float Distance(float[] vector1, float[] vector2)
        {            
            float dx = vector1[0] - vector2[0];            
            float dy = vector1[1] - vector2[1];
            float dz = vector1[2] - vector2[2];

            return (float)Math.Sqrt(dx * dx + dy * dy + dz * dz);
        }

        //distance between two vectors, with X mirrored
        public static float SqDistanceXMirror(float[] vector1, float[] vector2)
        {
            float dx = - vector1[0] - vector2[0];
            float dy = vector1[1] - vector2[1];
            float dz = vector1[2] - vector2[2];

            return (dx * dx + dy * dy + dz * dz);
        }

        // Add two vectors
        public static float[] Add(float[] vector1, float[] vector2)
        {
            return new float[3]
            {
            vector1[0] + vector2[0],
            vector1[1] + vector2[1],
            vector1[2] + vector2[2]
            };
        }

        // Subtract two vectors
        public static float[] Subtract(float[] vector1, float[] vector2)
        {
            return new float[3]
            {
            vector1[0] - vector2[0],
            vector1[1] - vector2[1],
            vector1[2] - vector2[2]
            };
        }
    }
}
