using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Numerics;
using System.Linq;
using System.Reflection;
using Autodesk.Max;
namespace Symmetry
{
    public static class Functions
    {
        private const uint EPolyMod13InterfaceA = 0x1a4cc8f2;
        private const uint EPolyMod13InterfaceB = 0x71682518;

        public static TResult FindPairs(float[][] positions, int[][] edges)
        {
            var links = ConvertEdgesToLinks(positions.Length, edges);
            var verts = new VertInfo(positions, links);
            var tolerance = 0.005f;

            var UnpairedSet = new HashSet<int>(Enumerable.Range(0, verts.NumVerts));

            // initializing verts information
            var sw = Stopwatch.StartNew();
            (var positiveVerts, var negativeVerts) = Initialize(verts, tolerance, UnpairedSet);
            Debug.WriteLine($"\nbuild-38\nInitializing {verts.NumVerts} verts");

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

        public static bool SetEditPolyVerts_Explore(ulong modifierHandle, ulong nodeHandle, int[] indices, float[][] positions)
        {
            Action<string> log = message => Debug.WriteLine(message);
            log("SetEditPolyVerts exploration begin");

            try
            {
                var global = GlobalInterface.Instance;
                log("GlobalInterface: " + (global != null ? "ok" : "null"));
                if (global == null)
                {
                    log("SetEditPolyVerts exploration end");
                    return false;
                }

                log("modifierHandle: " + modifierHandle);
                log("nodeHandle: " + nodeHandle);
                log("indices length: " + (indices != null ? indices.Length.ToString() : "null"));
                log("positions length: " + (positions != null ? positions.Length.ToString() : "null"));

                var modifierAnim = TryGetAnimByHandle(global, modifierHandle, "modifier", log);
                var modifier = modifierAnim as IModifier;
                log("modifier as IModifier: " + (modifier != null));

                if (modifier != null)
                {
                    TryDescribeModifier(modifier, log);
                }

                var nodeAnim = nodeHandle != 0 ? TryGetAnimByHandle(global, nodeHandle, "node", log) : null;
                var explicitNode = nodeAnim as IINode;
                log("explicit node as IINode: " + (explicitNode != null));
                if (explicitNode != null)
                {
                    log("explicit node name: " + explicitNode.Name);
                    log("explicit node handle: " + explicitNode.Handle);
                }

                if (modifier == null)
                {
                    log("SetEditPolyVerts exploration end");
                    return false;
                }

                var directCast = modifier as IEPolyMod13;
                log("modifier direct cast to IEPolyMod13: " + (directCast != null));

                var epolyMod = ResolveEPolyMod13(global, modifier);
                log("ResolveEPolyMod13: " + (epolyMod != null));
                if (epolyMod == null)
                {
                    log("SetEditPolyVerts exploration end");
                    return false;
                }

                IINode targetNode = explicitNode;
                if (targetNode == null)
                {
                    TryRunStep("EpModGetPrimaryNode", log, () =>
                    {
                        targetNode = epolyMod.EpModGetPrimaryNode;
                        log("EpModGetPrimaryNode null: " + (targetNode == null));
                    });
                }
                log("targetNode null: " + (targetNode == null));
                if (targetNode == null)
                {
                    log("SetEditPolyVerts exploration end");
                    return false;
                }

                log("targetNode name: " + targetNode.Name);
                log("targetNode handle: " + targetNode.Handle);

                var time = global.COREInterface.Time;
                log("time: " + time);
                IMatrix3 nodeTm = null;

                TryRunStep("GetNodeTM", log, () =>
                {
                    var valid = global.Interval.Create(time, time);
                    nodeTm = targetNode.GetNodeTM(time, valid);
                    log("GetNodeTM null: " + (nodeTm == null));
                });

                TryRunStep("EpModSetPrimaryNode", log, () =>
                {
                    epolyMod.EpModSetPrimaryNode(targetNode);
                    log("EpModSetPrimaryNode: ok");
                });

                log("About to call EpMeshGetNumVertices");
                var numVerts = epolyMod.EpMeshGetNumVertices(targetNode);
                log("numVerts: " + numVerts);
                var didWrite = false;

                if (numVerts > 0 && nodeTm != null)
                {
                    var testSlot = -1;
                    for (var i = 0; i < indices.Length; i++)
                    {
                        if (positions[i] == null || positions[i].Length != 3)
                        {
                            continue;
                        }
                        if (indices[i] < 1 || indices[i] > numVerts)
                        {
                            continue;
                        }
                        testSlot = i;
                        break;
                    }

                    if (testSlot >= 0)
                    {
                        var testIndex = indices[testSlot];
                        var currentPoint = default(IPoint3);
                        var targetLocalPoint = global.Point3.Create(positions[testSlot][0], positions[testSlot][1], positions[testSlot][2]);
                        var targetWorldPoint = nodeTm.PointTransform(targetLocalPoint);

                        log("testIndex: " + testIndex);
                        log("target local: [" + targetLocalPoint.X + ", " + targetLocalPoint.Y + ", " + targetLocalPoint.Z + "]");
                        log("target world: [" + targetWorldPoint.X + ", " + targetWorldPoint.Y + ", " + targetWorldPoint.Z + "]");

                        TryRunStep("EpMeshGetVertex(testIndex)", log, () =>
                        {
                            currentPoint = epolyMod.EpMeshGetVertex(testIndex, targetNode);
                            log("vertex before: [" + currentPoint.X + ", " + currentPoint.Y + ", " + currentPoint.Z + "]");
                        });

                        TryRunStep("EPMeshStartSetVertices", log, () =>
                        {
                            epolyMod.EPMeshStartSetVertices(targetNode);
                            log("EPMeshStartSetVertices: ok");
                        });

                        TryRunStep("EPMeshSetVert target value", log, () =>
                        {
                            epolyMod.EPMeshSetVert(testIndex, targetWorldPoint, targetNode);
                            log("EPMeshSetVert target value: ok");
                        });

                        TryRunStep("EPMeshEndSetVertices", log, () =>
                        {
                            epolyMod.EPMeshEndSetVertices(targetNode);
                            log("EPMeshEndSetVertices: ok");
                        });

                        TryRunStep("EpMeshGetVertex(testIndex) after", log, () =>
                        {
                            var afterPoint = epolyMod.EpMeshGetVertex(testIndex, targetNode);
                            log("vertex after: [" + afterPoint.X + ", " + afterPoint.Y + ", " + afterPoint.Z + "]");
                        });

                        TryRunStep("EpModRefreshScreen", log, () =>
                        {
                            epolyMod.EpModRefreshScreen();
                            log("EpModRefreshScreen: ok");
                        });

                        didWrite = true;
                    }
                }

                log("SetEditPolyVerts exploration end");
                return didWrite;
            }
            catch (Exception ex)
            {
                log("SetEditPolyVerts exploration threw: " + ex.GetType().FullName + ": " + ex.Message);
            }

            log("SetEditPolyVerts exploration end");
            return false;
        }

        public static bool SetEditPolyVerts(ulong modifierHandle, ulong nodeHandle, int[] indices, float[][] positions)
        {
            try
            {
                var global = GlobalInterface.Instance;
                if (!TryPrepareSetEditPolyVerts(global, modifierHandle, nodeHandle, indices, positions, out var modifier, out var epolyMod, out var node, out var numVerts))
                {
                    return false;
                }

                epolyMod.EpModSetPrimaryNode(node);

                var applied = 0;
                var started = false;

                try
                {
                    for (var i = 0; i < indices.Length; i++)
                    {
                        if (positions[i] == null || positions[i].Length != 3)
                        {
                            continue;
                        }

                        var vertIndex = indices[i];
                        if (vertIndex < 1 || vertIndex > numVerts)
                        {
                            continue;
                        }

                        if (!started)
                        {
                            epolyMod.EPMeshStartSetVertices(node);
                            started = true;
                        }

                        var objectPoint = global.Point3.Create(positions[i][0], positions[i][1], positions[i][2]);
                        epolyMod.EPMeshSetVert(vertIndex - 1, objectPoint, node);
                        applied++;
                    }
                }
                finally
                {
                    if (started)
                    {
                        epolyMod.EPMeshEndSetVertices(node);
                    }
                }

                if (applied == 0)
                {
                    return false;
                }
                var t = global.COREInterface.Time;
                epolyMod.EpModCommit(t);
                epolyMod.EpModRefreshScreen();
                return true;
            }
            catch (Exception ex)
            {
                Debug.WriteLine("SetEditPolyVerts failed: " + ex);
                return false;
            }
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

        private static IModifier ResolveModifier(IGlobal global, ulong modifierHandle)
        {
            var anim = global.Animatable.GetAnimByHandle(new UIntPtr(modifierHandle));
            return anim as IModifier;
        }

        private static IAnimatable TryGetAnimByHandle(IGlobal global, ulong handleValue, string label, Action<string> log)
        {
            try
            {
                var anim = global.Animatable.GetAnimByHandle(new UIntPtr(handleValue));
                log(label + " handle resolves: " + (anim != null));
                if (anim != null)
                {
                    log(label + " anim type: " + anim.GetType().FullName);
                }
                return anim;
            }
            catch (Exception ex)
            {
                log("GetAnimByHandle(" + label + ") threw: " + ex.GetType().Name + ": " + ex.Message);
                return null;
            }
        }

        private static void TryDescribeModifier(IModifier modifier, Action<string> log)
        {
            try
            {
                log("modifier name: " + modifier.GetName(false));
            }
            catch (Exception ex)
            {
                log("modifier.GetName threw: " + ex.GetType().Name + ": " + ex.Message);
            }

            try
            {
                var classId = modifier.ClassID;
                log("modifier classID: (" + classId.PartA + ", " + classId.PartB + ")");
            }
            catch (Exception ex)
            {
                log("modifier.ClassID threw: " + ex.GetType().Name + ": " + ex.Message);
            }

            try
            {
                log("modifier superClassID: " + modifier.SuperClassID);
            }
            catch (Exception ex)
            {
                log("modifier.SuperClassID threw: " + ex.GetType().Name + ": " + ex.Message);
            }
        }

        private static void TryRunStep(string label, Action<string> log, Action action)
        {
            try
            {
                action();
            }
            catch (Exception ex)
            {
                log(label + " threw: " + ex.GetType().Name + ": " + ex.Message);
            }
        }

        private static bool TryPrepareSetEditPolyVerts(
            IGlobal global,
            ulong modifierHandle,
            ulong nodeHandle,
            int[] indices,
            float[][] positions,
            out IModifier modifier,
            out IEPolyMod13 epolyMod,
            out IINode node,
            out int numVerts)
        {
            modifier = null;
            epolyMod = null;
            node = null;
            numVerts = 0;

            if (modifierHandle == 0 || indices == null || positions == null)
            {
                return false;
            }

            if (indices.Length != positions.Length)
            {
                return false;
            }

            if (global == null)
            {
                return false;
            }

            modifier = ResolveModifier(global, modifierHandle);
            if (modifier == null)
            {
                return false;
            }

            epolyMod = ResolveEPolyMod13(global, modifier);
            if (epolyMod == null)
            {
                return false;
            }

            node = ResolveNode(global, epolyMod, nodeHandle);
            if (node == null)
            {
                return false;
            }

            numVerts = epolyMod.EpMeshGetNumVertices(node);
            return numVerts > 0;
        }

        private static IINode ResolveNode(IGlobal global, IEPolyMod13 epolyMod, ulong nodeHandle)
        {
            if (nodeHandle != 0)
            {
                var anim = global.Animatable.GetAnimByHandle(new UIntPtr(nodeHandle));
                var node = anim as IINode;
                if (node != null)
                {
                    return node;
                }
            }

            return epolyMod.EpModGetPrimaryNode;
        }

        private static IEPolyMod13 ResolveEPolyMod13(IGlobal global, IModifier modifier)
        {
            if (modifier is IEPolyMod13 direct)
            {
                return direct;
            }

            var interfaceServer = modifier as IInterfaceServer;
            if (interfaceServer == null)
            {
                return null;
            }

            var interfaceId = global.Interface_ID.Create(EPolyMod13InterfaceA, EPolyMod13InterfaceB);
            var baseInterface = interfaceServer.GetInterface(interfaceId);
            if (baseInterface == null)
            {
                return null;
            }

            if (baseInterface is IEPolyMod13 typed)
            {
                return typed;
            }

            var native = baseInterface as INativeObject;
            if (native == null || native.NativePointer == IntPtr.Zero)
            {
                return null;
            }

            try
            {
            return global.EPolyMod13.Marshal(native.NativePointer);
        }
            catch
            {
                return null;
            }
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
