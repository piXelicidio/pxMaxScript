/*=============================================================
    Pair-Matching Heuristic  (PAMA)  —  MaxScript edition
    ---------------------------------------------------------
    pamaOrder  ptsArray
        • ptsArray : #(point3 …)  (RGB or XYZ, doesn’t matter)
        • returns  : #( idx0, idx1, … )  — visit order
=============================================================*/

/*--- tiny helper ----------------------------------------------------*/
fn edgeExists edgeArr a b =
(
    for e in edgeArr where ((e[1]==a and e[2]==b) or (e[1]==b and e[2]==a)) do return true
    false
)

/*--- main -----------------------------------------------------------*/
fn pamaOrder pts =
(
    local n       = pts.count
    local degree  = for i=1 to n collect 0
    local edges   = #()

    fn dist2 p q =
    (
        local v = p - q
        v.x*v.x + v.y*v.y + v.z*v.z
    )

    fn byDist a b = a[1] < b[1]    -- qSort comparator

    /*--- build degree=2 graph ------------------------------------*/
    local changed = true
    while changed do
    (
        changed = false
        local candidates = #()

        for i = 1 to n where degree[i] < 2 do
        (
            local bestJ  = 0
            local bestD2 = 1e9

            for j = 1 to n where (i!=j and degree[j]<2 and not edgeExists edges i j) do
            (
                local d2 = dist2 pts[i] pts[j]
                if d2 < bestD2 do (bestD2 = d2; bestJ = j)
            )

            if bestJ != 0 do append candidates #(bestD2, i, bestJ)
        )

        qSort candidates byDist

        for c in candidates do
        (
            local d2 = c[1]; local i = c[2]; local j = c[3]
            if degree[i]<2 and degree[j]<2 and not edgeExists edges i j do
            (
                append edges #(i,j)
                degree[i] += 1; degree[j] += 1
                changed = true
            )
        )
    )

    /*--- flatten components into a single order ------------------*/
    local adj = for k=1 to n collect #()
    for e in edges do
    (
        append adj[e[1]] e[2]
        append adj[e[2]] e[1]
    )

    local visited = for k=1 to n collect false
    local order   = #()

    for v = 1 to n where not visited[v] do
    (
        local entry = v   -- simple choice; good enough for =2 deg graph

        local prev = 0
        local cur  = entry
        while (cur != 0 and not visited[cur]) do
        (
            append order cur
            visited[cur] = true

            local nxt = 0
            for nb in adj[cur] where nb != prev while nxt == 0 do nxt = nb
            prev = cur
            cur  = nxt
        )
    )
    order    -- 1-based indices into pts
)

/*------------------------- demo -------------------------*/
seed 1
demoPts = for i=1 to 30 collect point3 (random 0 1) (random 0 1) (random 0 1)
visitOrder = pamaOrder demoPts
format "PAMA order:\n%\n" visitOrder
