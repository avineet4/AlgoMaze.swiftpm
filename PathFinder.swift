//
//  PathFinder.swift
//  AlgoMaze
//
//  Created by Avineet Singh on 19/02/25.
//

// Defines different Algos

import Foundation

actor PathFinder {
    private let maze: MazeState
    private let size: Int
    private var start: Point
    private var end: Point
    private var isPaused: Bool = false
    private var isStopped: Bool = false
    private var solveTime: TimeInterval = 0
    
    init(maze: MazeState) async {
        self.maze = maze
        self.size = maze.size
        self.start = Point(x: 0, y: 0)
        self.end = Point(x: 0, y: 0)
        await updateStartEnd()
    }
    
    func togglePause(_ paused: Bool) {
        self.isPaused = paused
    }
    
    
    func stop() async {
        self.isStopped = true
        self.isPaused = false
        await maze.resetPath()
    }
    
    private func checkState() async -> Bool {
        if isStopped { return true }
        while isPaused {
            if isStopped { return true }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return false
    }
    
    private func waitForAnimation() async {
        if !isStopped {
            try? await Task.sleep(nanoseconds: UInt64(await maze.animationSpeed * 1_000_000_000))
        }
    }
    
    private func updateStartEnd() async {
        self.start = await maze.start
        self.end = await maze.end
    }
    
    private func getNeighbors(of point: Point) async -> [Point] {
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        return await withTaskGroup(of: Point?.self) { group in
            for (dx, dy) in directions {
                let newX = point.x + dx
                let newY = point.y + dy
                
                group.addTask {
                    guard newX >= 0 && newX < self.size &&
                            newY >= 0 && newY < self.size else {
                        return nil
                    }
                    
                    let newPoint = Point(x: newX, y: newY)
                    return await self.maze.isWall(at: newPoint) ? nil : newPoint
                }
            }
            
            var neighbors: [Point] = []
            for await neighbor in group {
                if let neighbor {
                    neighbors.append(neighbor)
                }
            }
            return neighbors
        }
    }
    
    
    
    private func markVisitedIfAllowed(_ point: Point) async {
        guard !isStopped else { return }
        // Don't mark start/end points as visited
        if point != start && point != end {
            await maze.markVisited(point)
        }
        await waitForAnimation()
    }
    
    private func heuristic(from: Point, to: Point) -> Int {
        let dx = abs(from.x - to.x)
        let dy = abs(from.y - to.y)
        return dx + dy
    }
    
    // For Theta* which allows any-angle paths
    private func euclideanDistance(from: Point, to: Point) -> Double {
        let dx = Double(from.x - to.x)
        let dy = Double(from.y - to.y)
        return sqrt(dx * dx + dy * dy)
    }
    
    func findPath() async {
        let startTime = Date()
        isStopped = false
        solveTime = 0  // Reset solve time
        
        let algorithm = await maze.selectedAlgorithm
        switch algorithm {
        case .dijkstra:
            await findPathDijkstra()
        case .aStar:
            await findPathAStar()
        case .bfs:
            await findPathBFS()
        case .dfs:
            await findPathDFS()
        case .bidirectional:
            await findPathBidirectional()
        case .bestFirst:
            await findPathBestFirst()
        case .idaStar:
            await findPathIDAStar()
        case .fringe:
            await findPathFringe()
        case .theta:
            await findPathTheta()
        }
        
        if !isStopped {
            solveTime = Date().timeIntervalSince(startTime)  // Store the solve time
            let analytics = await maze.createAnalytics(
                timeToSolve: solveTime,
                pathLength: await maze.currentPath.count,
                visitedCells: await maze.visitedCells
            )
            await MainActor.run {
                maze.currentAnalytics = analytics
                maze.analyticsHistory.append(analytics)
            }
        }
    }
    
    // Instead of duplicating priority queue logic, create a generic type
    // Template type T
    private struct PriorityQueueElement<T> {
        let value: T
        let priority: Int
        
        // Higher priority values come first
        static func > (lhs: Self, rhs: Self) -> Bool {
            lhs.priority > rhs.priority
        }
    }
    
    
    
    private func findPathDijkstra() async {
        var frontier = [PriorityQueueElement(value: start, priority: 0)]
        var cameFrom: [Point: Point] = [:]
        var costSoFar: [Point: Int] = [start: 0]
        
        while !frontier.isEmpty {
            if await checkState() { return }
            
            frontier.sort(by: >)
            let current = frontier.removeLast().value
            
            if current == end { break }
            
            await markVisitedIfAllowed(current)
            
            let neighbors = await getNeighbors(of: current)
            for next in neighbors {
                let newCost = costSoFar[current]! + 1
                if costSoFar[next] == nil || newCost < costSoFar[next]! {
                    costSoFar[next] = newCost
                    frontier.append(PriorityQueueElement(value: next, priority: -newCost))
                    cameFrom[next] = current
                }
            }
        }
        
        if !isStopped {
            await reconstructPath(cameFrom: cameFrom)
        }
    }
    
    private func findPathAStar() async {
        var frontier = [PriorityQueueElement(value: start, priority: 0)]
        var cameFrom: [Point: Point] = [:]
        var costSoFar: [Point: Int] = [start: 0]
        
        while !frontier.isEmpty {
            if await checkState() { return }
            
            frontier.sort(by: >)
            let current = frontier.removeLast().value
            
            if current == end { break }
            
            await markVisitedIfAllowed(current)
            
            let neighbors = await getNeighbors(of: current)
            for next in neighbors {
                let newCost = costSoFar[current]! + 1
                if costSoFar[next] == nil || newCost < costSoFar[next]! {
                    costSoFar[next] = newCost
                    let priority = -(newCost + heuristic(from: next, to: end))
                    frontier.append(PriorityQueueElement(value: next, priority: priority))
                    cameFrom[next] = current
                }
            }
        }
        
        if !isStopped {
            await reconstructPath(cameFrom: cameFrom)
        }
    }
    
    private func findPathBFS() async {
        var frontier = [start]
        var cameFrom: [Point: Point] = [:]
        
        while !frontier.isEmpty {
            if await checkState() {
                return
            }
            
            let current = frontier.removeFirst()
            
            if current == end {
                break
            }
            
            await markVisitedIfAllowed(current)
            
            if !isStopped {
                try? await Task.sleep(nanoseconds: UInt64(await maze.animationSpeed * 1_000_000_000))
            }
            
            let neighbors = await getNeighbors(of: current)
            for next in neighbors where cameFrom[next] == nil {
                frontier.append(next)
                cameFrom[next] = current
            }
        }
        
        if !isStopped {
            await reconstructPath(cameFrom: cameFrom)
        }
    }
    
    
    
    private func findPathDFS() async {
        var frontier = [start]
        var cameFrom: [Point: Point] = [:]
        
        while !frontier.isEmpty {
            if await checkState() {
                return
            }
            
            let current = frontier.removeLast()
            
            if current == end {
                break
            }
            
            await markVisitedIfAllowed(current)
            
            if !isStopped {
                try? await Task.sleep(nanoseconds: UInt64(await maze.animationSpeed * 1_000_000_000))
            }
            
            let neighbors = await getNeighbors(of: current)
            for next in neighbors where cameFrom[next] == nil {
                frontier.append(next)
                cameFrom[next] = current
            }
        }
        
        if !isStopped {
            await reconstructPath(cameFrom: cameFrom)
        }
    }

    private func findPathBidirectional() async {
        var frontierStart = [start]
        var frontierEnd = [end]
        
        var cameFromStart: [Point: Point] = [:]
        var cameFromEnd: [Point: Point] = [:]
        
        var visitedStart = Set<Point>([start])
        var visitedEnd = Set<Point>([end])
        
        var meetingPoint: Point? = nil
        
        while !frontierStart.isEmpty && !frontierEnd.isEmpty && meetingPoint == nil {
            if await checkState() {
                return
            }
            
            // Forward search from start
            if !frontierStart.isEmpty {
                let current = frontierStart.removeFirst()
                // Mark visited only if it's not the start or end point
                if current != start && current != end {
                    await markVisitedIfAllowed(current)
                }
                
                if !isStopped {
                    try? await Task.sleep(nanoseconds: UInt64(await maze.animationSpeed * 1_000_000_000))
                }
                
                let neighbors = await getNeighbors(of: current)
                for next in neighbors {
                    if visitedEnd.contains(next) {
                        meetingPoint = next
                        cameFromStart[next] = current
                        break
                    }
                    
                    if !visitedStart.contains(next) {
                        frontierStart.append(next)
                        visitedStart.insert(next)
                        cameFromStart[next] = current
                    }
                }
            }
            
            // Backward search from end
            if !frontierEnd.isEmpty && meetingPoint == nil {
                let current = frontierEnd.removeFirst()
                // Mark visited only if it's not the start or end point
                if current != start && current != end {
                    await markVisitedIfAllowed(current)
                }
                
                if !isStopped {
                    try? await Task.sleep(nanoseconds: UInt64(await maze.animationSpeed * 1_000_000_000))
                }
                
                let neighbors = await getNeighbors(of: current)
                for next in neighbors {
                    if visitedStart.contains(next) {
                        meetingPoint = next
                        cameFromEnd[next] = current
                        break
                    }
                    
                    if !visitedEnd.contains(next) {
                        frontierEnd.append(next)
                        visitedEnd.insert(next)
                        cameFromEnd[next] = current
                    }
                }
            }
        }
        
        if !isStopped && meetingPoint != nil {
            await reconstructBidirectionalPath(
                cameFromStart: cameFromStart,
                cameFromEnd: cameFromEnd,
                meetingPoint: meetingPoint!
            )
        }
    }

    private func reconstructBidirectionalPath(
        cameFromStart: [Point: Point],
        cameFromEnd: [Point: Point],
        meetingPoint: Point
    ) async {
        // Build path from start to meeting point
        var pathToMeeting: [Point] = []
        var current = meetingPoint
        
        // Include the path from start to meeting point
        while let previous = cameFromStart[current] {
            pathToMeeting.append(previous)
            current = previous
        }
        
        // Build path from meeting point to end
        var pathFromMeeting: [Point] = [meetingPoint]  // Start with meeting point
        current = meetingPoint
        
        // Include the path from meeting point to end
        while let next = cameFromEnd[current] {
            pathFromMeeting.append(next)
            current = next
        }
        
        // Combine the paths:
        // 1. Reverse the path from start to meeting point
        // 2. Add the meeting point and the path to end
        let completePath = pathToMeeting.reversed() + pathFromMeeting
        
        await maze.markPath(completePath)
    }
    
    
    
    private func reconstructPath(cameFrom: [Point: Point]) async {
        var current = end
        var path: [Point] = [current]
        while current != start {
            current = cameFrom[current]!
            path.append(current)
        }
        await maze.markPath(path.reversed())
    }

    private func findPathBestFirst() async {
        var frontier = [PriorityQueueElement(value: start, priority: 0)]
        var cameFrom: [Point: Point] = [:]
        
        while !frontier.isEmpty {
            if await checkState() { return }
            
            frontier.sort(by: >)
            let current = frontier.removeLast().value
            
            if current == end { break }
            
            await markVisitedIfAllowed(current)
            
            let neighbors = await getNeighbors(of: current)
            for next in neighbors {
                if !cameFrom.keys.contains(next) {
                    // Priority is negative because we want smaller values to have higher priority
                    let priority = -heuristic(from: next, to: end)
                    frontier.append(PriorityQueueElement(value: next, priority: priority))
                    cameFrom[next] = current
                }
            }
        }
        
        if !isStopped {
            await reconstructPath(cameFrom: cameFrom)
        }
    }

    private func findPathIDAStar() async {
        var bound = heuristic(from: start, to: end)
        var cameFrom: [Point: Point] = [:]
        
        while true {
            if await checkState() { return }
            
            let (found, nextBound) = await search(
                current: start,
                g: 0,
                bound: bound,
                cameFrom: &cameFrom
            )
            
            if found {
                await reconstructPath(cameFrom: cameFrom)
                return
            }
            
            if nextBound == Int.max {
                // No path found
                return
            }
            
            bound = nextBound
        }
    }

    private func search(
        current: Point,
        g: Int,
        bound: Int,
        cameFrom: inout [Point: Point]
    ) async -> (found: Bool, nextBound: Int) {
        let f = g + heuristic(from: current, to: end)
        
        if f > bound {
            return (false, f)
        }
        
        if current == end {
            return (true, bound)
        }
        
        await markVisitedIfAllowed(current)
        
        var minBound = Int.max
        let neighbors = await getNeighbors(of: current)
        
        for next in neighbors {
            if !cameFrom.keys.contains(next) {
                cameFrom[next] = current
                
                let (found, nextBound) = await search(
                    current: next,
                    g: g + 1,
                    bound: bound,
                    cameFrom: &cameFrom
                )
                
                if found {
                    return (true, bound)
                }
                
                if nextBound < minBound {
                    minBound = nextBound
                }
                
                cameFrom.removeValue(forKey: next)
            }
        }
        
        return (false, minBound)
    }

    private func findPathFringe() async {
        var flimit = heuristic(from: start, to: end)
        var cameFrom: [Point: Point] = [:]
        var fScore: [Point: Int] = [start: flimit]
        var fringe = [start]
        
        while !fringe.isEmpty {
            if await checkState() { return }
            
            var fmin = Int.max
            var i = 0
            
            while i < fringe.count {
                let current = fringe[i]
                let f = fScore[current] ?? Int.max
                
                if f > flimit {
                    fmin = min(f, fmin)
                    i += 1
                    continue
                }
                
                if current == end {
                    await reconstructPath(cameFrom: cameFrom)
                    return
                }
                
                await markVisitedIfAllowed(current)
                fringe.remove(at: i)
                
                // Add animation delay
                if !isStopped {
                    try? await Task.sleep(nanoseconds: UInt64(await maze.animationSpeed * 1_000_000_000))
                }
                
                let neighbors = await getNeighbors(of: current)
                for next in neighbors {
                    let g = (fScore[current] ?? 0) - heuristic(from: current, to: end) + 1
                    let f = g + heuristic(from: next, to: end)
                    
                    if let existingF = fScore[next], f >= existingF {
                        continue
                    }
                    
                    fScore[next] = f
                    cameFrom[next] = current
                    
                    // Insert into fringe maintaining order
                    let insertIndex = fringe.firstIndex { (fScore[$0] ?? Int.max) > f } ?? fringe.count
                    fringe.insert(next, at: insertIndex)
                }
            }
            
            if fmin == Int.max { break }
            flimit = fmin
        }
    }
    

    private func findPathTheta() async {
        var frontier = [PriorityQueueElement(value: start, priority: 0)]
        var cameFrom: [Point: Point] = [:]
        var gScore: [Point: Int] = [start: 0]
        var visited: Set<Point> = []
        
        func lineOfSight(_ from: Point, _ to: Point) async -> Bool {
            let dx = abs(to.x - from.x)
            let dy = abs(to.y - from.y)
            var x = from.x
            var y = from.y
            let n = 1 + dx + dy
            let xInc = to.x > from.x ? 1 : -1
            let yInc = to.y > from.y ? 1 : -1
            var error = dx - dy
            let dx2 = dx * 2
            let dy2 = dy * 2
            
            // Collect all points along the line
            var points: [Point] = []
            for _ in 0..<n {
                let point = Point(x: x, y: y)
                points.append(point)
                
                if error > 0 {
                    x += xInc
                    error -= dy2
                } else {
                    y += yInc
                    error += dx2
                }
            }
            
            // Check if all points are valid
            for point in points {
                let isValid = await isValidPoint(point)
                if !isValid {
                    return false
                }
            }
            return true
        }
        
        func reconstructThetaPath(cameFrom: [Point: Point]) async {
            var current = end
            var path: [Point] = [current]
            
            while current != start {
                let next = cameFrom[current]!
                // Add intermediate points if they exist
                if await lineOfSight(current, next) {
                    let dx = current.x - next.x
                    let dy = current.y - next.y
                    let steps = max(abs(dx), abs(dy))
                    if steps > 1 {
                        for i in 1..<steps {
                            let x = next.x + (dx * i) / steps
                            let y = next.y + (dy * i) / steps
                            path.append(Point(x: x, y: y))
                        }
                    }
                }
                path.append(next)
                current = next
            }
            
            await maze.markPath(path.reversed())
        }
        
        while !frontier.isEmpty {
            if await checkState() { return }
            
            frontier.sort(by: >)
            let current = frontier.removeLast().value
            
            if current == end {
                await reconstructThetaPath(cameFrom: cameFrom)  // Use the new reconstruction method
                return
            }
            
            if visited.contains(current) { continue }
            visited.insert(current)
            
            await markVisitedIfAllowed(current)
            
            // Add animation delay
            if !isStopped {
                try? await Task.sleep(nanoseconds: UInt64(await maze.animationSpeed * 1_000_000_000))
            }
            
            let neighbors = await getNeighbors(of: current)
            for next in neighbors {
                if visited.contains(next) { continue }
                
                let parent = cameFrom[current] ?? current
                let hasLineOfSight = await lineOfSight(parent, next)
                let newG: Int
                
                if hasLineOfSight {
                    newG = (gScore[parent] ?? 0) + heuristic(from: parent, to: next)
                    cameFrom[next] = parent
                } else {
                    newG = (gScore[current] ?? 0) + heuristic(from: current, to: next)
                    cameFrom[next] = current
                }
                
                if gScore[next] == nil || newG < gScore[next]! {
                    gScore[next] = newG
                    let priority = -(newG + heuristic(from: next, to: end))
                    frontier.append(PriorityQueueElement(value: next, priority: priority))
                }
            }
        }
    }
    

    private func isValidPoint(_ point: Point) async -> Bool {
        // Check bounds
        guard point.x >= 0 && point.x < maze.size &&
              point.y >= 0 && point.y < maze.size else {
            return false
        }
        
        // Check if point is not a wall
        let grid = await maze.grid
        return grid[point.y][point.x] != .wall
    }
    
    
    
    // Add a method to get the current solve time
    func getCurrentSolveTime() -> TimeInterval {
        solveTime
    }
}
