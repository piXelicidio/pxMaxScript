using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Numerics;
using System.Linq;
using System.Reflection;
namespace Symmetry
{
    public static class Functions
    {

        public static TResult FindPairs(float[][] positions, int[][] edges)
        {
            var links = ConvertEdgesToLinks(positions.Length, edges);
            var verts = new VertInfo(positions, links);
            var tolerance = 0.005f;

            var UnpairedSet = new HashSet<int>(Enumerable.Range(0, verts.NumVerts));

            // initializing verts information
            var sw = Stopwatch.StartNew();
            (var positiveVerts, var negativeVerts) = Initialize(verts, tolerance, UnpairedSet);
            Debug.WriteLine($"\nbuild-22\nInitializing {verts.NumVerts} verts");

            sw.Restart();
            //finding pairs by position
            foreach (int v1_idx in positiveVerts)
            {
                var v1 = verts.positions[v1_idx];
                foreach (int v2_idx in negativeVerts)
                {
                    var v2 = verts.positions[v2_idx];
                    if (Math.Abs(-v2[0] - v1[0]) < tolerance && 
                        Math.Abs(v2[1] - v1[1]) < tolerance &&
                        Math.Abs(v2[2] - v1[2]) < tolerance)
                    {
                        //building relationships
                        verts.pairedWith[v1_idx] = v2_idx;
                        verts.pairedWith[v2_idx] = v1_idx;
                        UnpairedSet.Remove(v1_idx);
                        UnpairedSet.Remove(v2_idx);
                    }
                }
            }
            Debug.WriteLine($"Pairs by position: {sw.ElapsedMilliseconds}ms");
            sw.Restart();

            //incoming cool stuff 
            PairByEdgeConnections(verts, UnpairedSet);

            Debug.WriteLine($"Pairing by edges: {sw.ElapsedMilliseconds}ms");
            sw.Restart();

            //return ToMxsArray(Result);
            var res = new TResult();
            res.unpaired = ToMxsArray(UnpairedSet);
            res.rightSide = verts.rightSide;
            res.pairedWith = verts.pairedWith; //this is 0 based, remember add 1 in MaxScript.
            foreach (var li in links)
            {
                for (var i = 0; i < li.Length; i++)
                {
                    li[i]++;
                }
            }
            res.connections = links;
            
            
            return res;
        }

        public static int[][] ConvertEdgesToLinks(int vertCount, int[][] edges)
        {
            //converting edges to list of linked vertices (links)
            var linkDict = new Dictionary<int, List<int>>();
            List<int> linkList; 
            
            foreach (int[] edge in edges)
            {
                if (linkDict.TryGetValue(edge[0]-1, out linkList))
                {
                    linkList.Add(edge[1]-1);
                }
                else
                {
                    linkList = new List<int>() { edge[1]-1 };
                    linkDict.Add(edge[0] - 1, linkList);
                }
                if (linkDict.TryGetValue(edge[1] - 1, out linkList))
                {
                    linkList.Add(edge[0] - 1);
                }
                else
                {
                    linkList = new List<int>() { edge[0] - 1 };
                    linkDict.Add(edge[1] - 1, linkList);
                }
            }

            var links = new int[vertCount][];
            for (var i = 0; i < vertCount; i++)
            {
                if (linkDict.TryGetValue(i, out linkList))
                {
                    links[i] = linkList.ToArray();
                }
                else
                {
                    links[i] = new int[0];
                }
            }
            return links;
        }

        private static (List<int> positiveVerts, List<int> negativeVerts) Initialize(VertInfo vertsInfo, float tolerance, HashSet<int> UnpairedSet)
        {
            var positive = new List<int>();
            var negative = new List<int>();
            for (int i = 0; i < vertsInfo.NumVerts; i++)
            {
                var v = vertsInfo.positions[i];
                vertsInfo.pairedWith[i] = -1; //undefined pair
                if (Vec3.X(v) >= 0)
                {
                    vertsInfo.rightSide[i] = true;
                    positive.Add(i);
                }
                else
                {
                    negative.Add(i);
                }            

                //those in the center (close to x = 0) paired with themselves
                if (Math.Abs(Vec3.X(v)) <= tolerance)
                {
                    vertsInfo.pairedWith[i] = i;
                    UnpairedSet.Remove(i);
                }

            }
            return (positive, negative);
        }

        //PAIR BY EDGE CONNECTION ANALYSIS
        private static void PairByEdgeConnections(VertInfo verts, HashSet<int> UnpairedSet)
        {
            var UnpairedBorder = new HashSet<int>();
            void CheckIfBorder(int index)
            {
                int link = 0;
                bool nextToPaired = false;
                int len = verts.linkedTo[index].Length;
                while (!nextToPaired && link < len)
                {
                    nextToPaired = verts.pairedWith[verts.linkedTo[index][link]] >= 0;
                    link++;
                }
                if (nextToPaired)
                {
                    UnpairedBorder.Add(index);
                }
            }

            //Narrowing the search to just the border of interest.
            foreach (var uIndex in UnpairedSet) CheckIfBorder(uIndex);            

            int FoundNewPairs;
            do
            {              
                var UnpairedList = UnpairedBorder.ToArray(); //Need a copy, to modify the original.
                FoundNewPairs = 0;
                foreach (var RIndex in UnpairedList)
                {
                    var RightSymLinks = new HashSet<int>();
                    int RightUnpairedLinks = 0;
                    foreach (var k in verts.linkedTo[RIndex])
                    {
                        if (verts.pairedWith[k] == -1) RightUnpairedLinks++; 
                        else RightSymLinks.Add(k);
                    }

                    if (verts.pairedWith[RIndex] == -1 && RightSymLinks.Count > 0)
                    {
                        int MyCandidate = -1;
                        int MyCandidateNum = 0;
                        foreach (var LIndex in UnpairedList)
                        {
                            var LeftSymLinks = new HashSet<int>();
                            int LeftUnpairedLinks = 0;
                            //collect both sides pairs                           
                            foreach (var k in verts.linkedTo[LIndex])
                            {
                                if (verts.pairedWith[k] == -1) LeftUnpairedLinks++;
                                else LeftSymLinks.Add(verts.pairedWith[k]);
                            }                           

                            if (LeftSymLinks.Count > 0
                                && RightSymLinks.SetEquals(LeftSymLinks)
                                && RightUnpairedLinks == LeftUnpairedLinks)
                            {
                                // This is a good candidate
                                MyCandidateNum++;
                                if (MyCandidate == -1)
                                {
                                    // Is the first one, hopefully the only one
                                    MyCandidate = LIndex;
                                }
                            }
                        }

                        //if one and only one then is good to go, else... think later                        
                        if (MyCandidateNum == 1)
                        {
                            //we can pair vert I with vert MyCandidate
                            verts.pairedWith[RIndex] = MyCandidate;
                            verts.pairedWith[MyCandidate] = RIndex;
                            FoundNewPairs++;
                            UnpairedSet.Remove(RIndex);
                            UnpairedSet.Remove(MyCandidate);
                        }
                    }
                }

                //Rebuilding the border, just close to the old border
                UnpairedBorder.Clear();
                foreach (var idx in UnpairedList)
                {
                    foreach (var uIndex in verts.linkedTo[idx])
                    {
                        if (verts.pairedWith[uIndex] < 0)
                        {
                            CheckIfBorder(uIndex);
                        }
                    }
                }

            } while (FoundNewPairs > 0);

        }



        public struct TResult
        {
            public int[] unpaired;
            public bool[] rightSide;
            public int[] pairedWith;
            public int[][] connections;
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

    internal class VertInfo
    {
        public float[][] positions;
        public int[][] linkedTo;
        public bool[] rightSide;
        public int[] pairedWith;
        public int NumVerts { get; private set; }

        public VertInfo(float[][] vertPositions, int[][] vertLinkedTo)
        {
            positions = vertPositions;
            linkedTo = vertLinkedTo;
            NumVerts = vertPositions.Length;
            rightSide = new bool[NumVerts];
            pairedWith = new int[NumVerts];
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
