// Models.swift

import SwiftUI

// MARK: - Data Structures
struct Point: Hashable, Codable {
    let x: Int
    let y: Int
}

struct Edge: Hashable, Codable {
    let from: Point
    let to: Point
    let weight: Int
}

enum MazeCellType {
    case wall
    case path
    case start
    case end
    case visited
    case current
}

enum PathfindingAlgo: String, CaseIterable {
    case dijkstra = "Dijkstra's Algorithm"
    case aStar = "A* Search"
    case bfs = "Breadth-First Search"
    case dfs = "Depth-First Search"
    case bidirectional = "Bidirectional Search"
    case bestFirst = "Best-First Search"
    case idaStar = "IDA* Search"
    case fringe = "Fringe Search"
    case theta = "Theta*"
    
    var description: String {
        switch self {
        case .dijkstra:
            return "Finds the shortest path by considering the distance from start to each node."
        case .aStar:
            return "Like Dijkstra's but uses heuristics to guide the search toward the goal."
        case .bfs:
            return "Explores nodes level by level, guaranteeing shortest path in unweighted graphs."
        case .dfs:
            return "Explores as far as possible along each branch before backtracking."
        case .bidirectional:
            return "Searches simultaneously from both start and end points, meeting in the middle."
        case .bestFirst:
            return "A greedy variant that always chooses the node that looks closest to the goal, trading optimality for speed."
        case .idaStar:
            return "Memory-efficient variant of A* that uses depth-first search with an increasing depth limit, ideal for large mazes."
        case .fringe:
            return "Memory-efficient alternative to A* that maintains a fringe of nodes to explore."
        case .theta:
            return "Finds smoother paths by allowing any-angle movement through corners when line of sight exists."
        }
    }
    
    var complexity: (time: String, space: String) {
        switch self {
        case .dijkstra:
            return (time: "O((V + E) log V)", space: "O(V)")
        case .aStar:
            return (time: "O(b^d)", space: "O(b^d)")
        case .bfs:
            return (time: "O(V + E)", space: "O(V)")
        case .dfs:
            return (time: "O(V + E)", space: "O(V)")
        case .bidirectional:
            return (time: "O(b^(d/2))", space: "O(b^(d/2))")
        case .bestFirst:
            return (time: "O(V + E)", space: "O(V)")
        case .idaStar:
            return (time: "O(b^d)", space: "O(d)")
        case .fringe:
            return (time: "O(V log V)", space: "O(V)")
        case .theta:
            return (time: "O(V^2)", space: "O(V)")
        }
    }
    
    var complexityExplanation: String {
        switch self {
        case .dijkstra:
            return "V is the number of vertices (cells), E is the number of edges (connections between cells). The log V factor comes from priority queue operations."
        case .aStar:
            return "With a good heuristic, A* can be much faster than Dijkstra's algorithm in practice, though it has similar worst-case complexity."
        case .bfs:
            return "Visits all vertices and edges once, with space proportional to the frontier size."
        case .dfs:
            return "Explores all vertices and edges, with space proportional to the maximum path length."
        case .bidirectional:
            return "b is the branching factor (typically 4 in a maze), d is the shortest path length. Meets in the middle, effectively halving the depth."
        case .bestFirst:
            return "Similar to BFS but uses a heuristic to guide the search. May not find the optimal path."
        case .idaStar:
            return "d is the depth of the solution, b is the branching factor. Space-efficient but may re-explore states."
        case .fringe:
            return "Similar to A* but with different memory characteristics. Good for large mazes."
        case .theta:
            return "Can find any-angle paths but requires checking line-of-sight between many pairs of vertices."
        }
    }
    
    var AlgoWorking: String {
        switch self {
        case .dijkstra:
            return """
            1. Maintains a priority queue of nodes to explore
            2. For each node, keeps track of the shortest known distance from start
            3. Repeatedly selects the unvisited node with smallest distance
            4. Updates distances to all neighbors through the current node
            5. Marks current node as visited and continues until reaching the end
            
            The algorithm guarantees the shortest path by always exploring the closest unvisited node first.
            """
        case .aStar:
            return """
            1. Similar to Dijkstra's but uses a heuristic function
            2. Priority = actual distance from start + estimated distance to end
            3. Heuristic function (Manhattan distance) guides search toward goal
            4. Maintains open and closed sets of nodes
            5. Explores most promising paths first
            
            The heuristic function makes A* more efficient than Dijkstra's for most cases.
            """
        case .bfs:
            return """
            1. Uses a queue to explore nodes in order of distance from start
            2. Visits all nodes at current distance before moving further
            3. Guarantees shortest path in unweighted graphs
            4. Explores in a wave-like pattern
            5. Simple to implement but can be memory-intensive
            
            Perfect for finding shortest paths when all edges have equal weight.
            """
        case .dfs:
            return """
            1. Uses a stack to explore as far as possible along each branch
            2. Backtracks only when reaching a dead end
            3. Memory efficient but doesn't guarantee shortest path
            4. Good for maze solving and topological sorting
            5. Can get stuck in deep paths
            
            Useful when memory is limited or when finding any path is sufficient.
            """
        case .bidirectional:
            return """
            1. Runs two simultaneous searches
            2. One search from start, another from goal
            3. Terminates when searches meet in the middle
            4. Can significantly reduce search space
            5. Requires careful handling of the meeting point
            
            Especially effective in large mazes where paths tend to be long.
            """
        case .bestFirst:
            return """
            1. Greedy approach that always moves toward the goal
            2. Uses heuristic function without considering path cost
            3. Very fast but may not find optimal path
            4. Simple to implement and memory efficient
            5. Good for real-time applications
            
            Useful when speed is more important than path optimality.
            """
        case .idaStar:
            return """
            1. Combines depth-first search with A* heuristic
            2. Uses iterative deepening with a cost threshold
            3. Increases threshold when path not found
            4. Very memory efficient
            5. Can be slower due to repeated searches
            
            Excellent for large mazes where memory is limited.
            """
        case .fringe:
            return """
            1. Similar to A* but with different node selection
            2. Maintains a fringe of promising nodes
            3. More efficient memory usage than A*
            4. Good balance of speed and memory
            5. Complex implementation but powerful results
            
            Particularly good for large-scale pathfinding problems.
            """
        case .theta:
            return """
            1. Finds paths that can move at any angle
            2. Checks line-of-sight between nodes
            3. Can produce more natural paths
            4. More computationally intensive
            5. Requires additional geometric calculations
            
            Best for open spaces where diagonal movement is allowed.
            """
        }
    }
    
    var uses: String {
        switch self {
        case .dijkstra:
            return """
            • Network routing (IP routing, OSPF)
            • GPS and navigation systems
            • Social networks (finding shortest connections)
            • Supply chain optimization
            • Utility networks (water, electricity)
            
            Best for weighted graphs when the optimal path must be guaranteed.
            """
        case .aStar:
            return """
            • Video game AI pathfinding
            • Robotics navigation
            • Logistics route planning
            • GPS with traffic consideration
            • Autonomous vehicle routing
            
            Ideal for scenarios with a good distance heuristic to the goal.
            """
        case .bfs:
            return """
            • Social network friend suggestions
            • Web crawling and indexing
            • Network broadcast systems
            • Puzzle solving (minimum moves)
            • File system traversal
            
            Perfect for unweighted graphs and finding shortest paths by number of edges.
            """
        case .dfs:
            return """
            • Maze generation and solving
            • File system searching
            • Game tree exploration
            • Circuit design verification
            • Topological sorting
            
            Best for deep graph exploration and memory-constrained environments.
            """
        case .bidirectional:
            return """
            • Large-scale route planning
            • Database query optimization
            • DNA sequence alignment
            • Word ladder puzzles
            • Meeting point optimization
            
            Efficient for problems where both start and end states are known.
            """
        case .bestFirst:
            return """
            • Real-time game AI
            • Emergency response routing
            • Resource allocation
            • Quick path approximation
            • Dynamic obstacle avoidance
            
            Suitable when quick solutions are needed over optimal ones.
            """
        case .idaStar:
            return """
            • Sliding puzzle solvers
            • Embedded systems navigation
            • Memory-limited devices
            • Pattern matching
            • Game tree search
            
            Perfect for large search spaces with strict memory constraints.
            """
        case .fringe:
            return """
            • Large terrain navigation
            • City infrastructure planning
            • Network flow optimization
            • Resource distribution
            • Traffic routing systems
            
            Good for complex pathfinding with better memory efficiency than A*.
            """
        case .theta:
            return """
            • Drone flight planning
            • Robot motion planning
            • 3D game navigation
            • Virtual reality movement
            • Autonomous vehicle routing
            
            Ideal for scenarios requiring smooth paths with any-angle movement.
            """
        }
    }
    
    var guaranteesShortestPath: Bool {
        switch self {
        case .dijkstra: return true   // Always finds shortest path in weighted graphs
        case .aStar: return true      // Finds shortest path if heuristic is admissible
        case .bfs: return true        // Finds shortest path in unweighted graphs
        case .dfs: return false       // Does not guarantee shortest path
        case .bidirectional: return true // Finds shortest path if implemented correctly
        case .bestFirst: return false // Greedy approach, no guarantee
        case .idaStar: return true    // Finds shortest path with iterative deepening
        case .fringe: return true     // Finds shortest path like A*
        case .theta: return true      // Finds shortest any-angle path
        }
    }
    
    var isComplete: Bool {
        switch self {
        case .dijkstra: return true   // Will find path if one exists
        case .aStar: return true      // Will find path if one exists
        case .bfs: return true        // Will find path if one exists
        case .dfs: return true        // Will find path if one exists
        case .bidirectional: return true // Will find path if one exists
        case .bestFirst: return true  // Will find path if one exists
        case .idaStar: return true    // Will find path if one exists
        case .fringe: return true     // Will find path if one exists
        case .theta: return true      // Will find path if one exists
        }
    }
}

enum MazeGenerationAlgo: String, CaseIterable {
    case kruskal = "Kruskal's Algorithm"
    case prim = "Prim's Algorithm"
    case wilson = "Wilson's Algorithm"
    case recursiveDivision = "Recursive Division"
    case randomizedBraided = "Randomized Braided"
    case cellular = "Cellular Automata"
    case huntAndKill = "Hunt-and-Kill"
    case spiralBacktracker = "Spiral Backtracker"
    
    var description: String {
        switch self {
        case .kruskal:
            return "Creates a perfect maze using a randomized spanning tree algorithm, ensuring exactly one path between any two points."
        case .prim:
            return "Builds the maze outward from a single starting point, creating a tree-like structure with a more organic flow."
        case .wilson:
            return "Generates perfectly uniform random mazes using loop-erased random walks, producing unbiased results."
        case .recursiveDivision:
            return "Creates structured mazes by recursively dividing the space into chambers and adding passages between them."
        case .randomizedBraided:
            return "Generates mazes with multiple possible solutions by strategically removing dead ends from a perfect maze."
        case .cellular:
            return "Creates organic, cave-like structures using cellular automata rules, resulting in natural-looking passages."
        case .huntAndKill:
            return "Produces mazes with long, winding corridors by combining random walks with systematic hunting patterns."
        case .spiralBacktracker:
            return "Generates mazes with a distinctive spiral pattern while maintaining randomness in branch creation."
        }
    }
    
    var allowsMultiplePaths: Bool {
        switch self {
        case .recursiveDivision, .randomizedBraided, .cellular:
            return true
        default:
            return false
        }
    }
    
    
    
    
    var characteristics: String {
        switch self {
        case .kruskal:
            return """
            • Creates very random, unbiased mazes
            • Tends to have many short dead ends
            • Produces an 'organic' feel
            • All paths have equal probability
            • Good for generating varied mazes
            
            The algorithm treats all possible paths equally, resulting in well-distributed mazes.
            """
        case .prim:
            return """
            • Generates 'river-like' flowing paths
            • Builds maze from a single point
            • Creates more winding passages
            • Fewer but longer dead ends
            • More structured feel than Kruskal's
            
            Results in mazes that feel more designed and less random.
            """
        case .wilson:
            return """
            • Creates unbiased perfect mazes
            • Uses loop-erased random walks
            • Very uniform distribution
            • Can be slower than other methods
            • Produces high-quality mazes
            
            Excellent for generating mathematically perfect mazes.
            """
        case .recursiveDivision:
            return """
            • Creates regular, geometric patterns
            • Allows for multiple paths
            • Highly customizable
            • Fast execution
            • Creates distinct chambers
            
            Good for generating mazes with a more structured appearance.
            """
        case .randomizedBraided:
            return """
            • Multiple paths between points
            • Fewer dead ends than perfect mazes
            • Random removal of walls
            • Creates loops and cycles
            • Good for easier navigation
            
            Ideal for generating mazes with multiple solution paths.
            """
        case .cellular:
            return """
            • Creates organic, cave-like structures
            • Uses cellular automata rules
            • Natural-looking passages
            • Variable path widths
            • Emergent patterns
            
            Perfect for generating natural-looking maze environments.
            """
        case .huntAndKill:
            return """
            • Creates long, winding corridors
            • Fewer dead ends than Kruskal/Prim
            • More challenging to solve
            • Systematic generation pattern
            • Good maze complexity
            
            Excellent for creating challenging but fair mazes.
            """
        case .spiralBacktracker:
            return """
            • Distinctive spiral patterns
            • Predictable generation pattern
            • Unique visual appearance
            • Consistent difficulty level
            • Interesting solving experience
            
            Best for creating mazes with a specific visual style.
            """
        }
    }
    
    var complexity: (time: String, space: String) {
            switch self {
            case .kruskal:
                return (time: "O(E log V)", space: "O(V)")
            case .prim:
                return (time: "O(E log V)", space: "O(V)")
            case .wilson:
                return (time: "O(V^2)", space: "O(V)")
            case .recursiveDivision:
                return (time: "O(V log V)", space: "O(V)")
            case .randomizedBraided:
                return (time: "O(V)", space: "O(1)")
            case .cellular:
                return (time: "O(V)", space: "O(V)")
            case .huntAndKill:
                return (time: "O(V^2)", space: "O(V)")
            case .spiralBacktracker:
                return (time: "O(V)", space: "O(V)")
            }
        }
    
    var complexityExplanation: String {
            switch self {
            case .kruskal:
                return "V is the number of vertices (cells), E is the number of possible walls to remove. Uses a disjoint set data structure for efficiency."
            case .prim:
                return "Similar to Kruskal's but grows a single tree from a starting point using a priority queue."
            case .wilson:
                return "Uses loop-erased random walks to generate unbiased mazes. Higher time complexity but produces perfectly uniform mazes."
            case .recursiveDivision:
                return "Recursively divides the space into chambers, adding passages between them. Very efficient for large mazes."
            case .randomizedBraided:
                return "Linear time complexity as it makes a single pass through the grid, with constant extra space needed."
            case .cellular:
                return "Applies cellular automata rules in a single pass, storing the current state of all cells."
            case .huntAndKill:
                return "Must hunt for unvisited cells when stuck, leading to quadratic worst-case time complexity."
            case .spiralBacktracker:
                return "Makes a single spiral pass through the grid, maintaining a stack of visited cells."
            }
        }
    
    var hasBias: Bool {
        switch self {
        case .kruskal, .wilson: return false
        case .prim, .recursiveDivision, .randomizedBraided, .cellular, .huntAndKill, .spiralBacktracker: return true
        }
    }
    
    var generationStyle: String {
        switch self {
        case .kruskal, .prim: return "Tree-based"
        case .wilson: return "Random Walk"
        case .recursiveDivision: return "Divide & Conquer"
        case .randomizedBraided: return "Iterative"
        case .cellular: return "Cellular Automata"
        case .huntAndKill: return "Backtracking"
        case .spiralBacktracker: return "Spiral Pattern"
        }
    }
    
    var howItWorks: String {
        switch self {
        case .kruskal:
            return """
            1. Initialize all cells as walls with potential passages between them
            2. Assign each cell to its own set
            3. Randomly select walls between cells
            4. If cells on either side are in different sets, remove wall and merge sets
            5. Continue until all cells are connected in one set
            
            Uses disjoint sets to prevent cycles while ensuring connectivity.
            """
        case .prim:
            return """
            1. Start with a grid full of walls
            2. Choose a starting cell and mark it as part of the maze
            3. Add all walls adjacent to the starting cell to a list
            4. While walls remain in the list:
               - Pick a random wall
               - If one cell is in maze and other isn't, connect them
            5. Add new walls to the list and continue
            
            Creates mazes with a more organic, flowing pattern.
            """
        case .wilson:
            return """
            1. Start with all cells as walls
            2. Mark one cell as visited
            3. Pick an unvisited cell and perform random walk until hitting visited cell
            4. Erase all loops created during the walk
            5. Add the final path to the maze and repeat
            
            Guarantees uniform distribution of all possible maze patterns.
            """
        case .recursiveDivision:
            return """
            1. Begin with an empty grid
            2. Divide the grid into two sub-chambers with a wall
            3. Create at least one passage through the wall
            4. Recursively apply the process to each sub-chamber
            5. Stop when chambers reach minimum size
            
            Results in mazes with clear hierarchical structure.
            """
        case .randomizedBraided:
            return """
            1. Generate a perfect maze as the base
            2. Identify all dead ends in the maze
            3. For each dead end, randomly decide to remove it
            4. When removing, connect to nearest passage
            5. Ensure maze remains solvable after modifications
            
            Creates multiple solution paths while maintaining maze-like character.
            """
        case .cellular:
            return """
            1. Initialize grid with random wall/path distribution
            2. For each cell, count number of surrounding walls
            3. Apply rules based on neighbor count:
               - Too few neighbors: become wall
               - Too many neighbors: become wall
               - Just right: become path
            4. Repeat process several times
            5. Clean up isolated cells and ensure connectivity
            
            Produces natural-looking cave systems and passages.
            """
        case .huntAndKill:
            return """
            1. Start at a random cell and mark as path
            2. While possible, randomly walk to unvisited cells
            3. When stuck, enter 'hunt' mode:
               - Scan for unvisited cell adjacent to path
               - When found, connect and resume random walk
            4. Continue until no unvisited cells remain
            5. Clean up and ensure start/end accessibility
            
            Creates mazes with longer corridors and fewer dead ends.
            """
        case .spiralBacktracker:
            return """
            1. Start from a corner of the maze
            2. Follow a spiral pattern toward center
            3. When blocked, backtrack to last branch point
            4. Create random branches off main spiral
            5. Ensure connectivity while maintaining spiral pattern
            
            Combines structured pattern with randomized elements.
            """
        }
    }
}

struct AlgorithmAnalytics: Codable {
    let mazeId: UUID
    let algorithm: PathfindingAlgo
    let mazeAlgorithm: MazeGenerationAlgo
    let timeToSolve: TimeInterval
    let pathLength: Int
    let cellsVisited: Int
    let timestamp: Date
    let visitedPoints: [Point]
    let pathPoints: [Point]
    let mazeGrid: [[MazeCellType]]
    
    // Add a computed property to get clean maze grid
    var cleanMazeGrid: [[MazeCellType]] {
        var clean = mazeGrid
        for y in 0..<clean.count {
            for x in 0..<clean[y].count {
                if clean[y][x] == .visited || clean[y][x] == .current {
                    clean[y][x] = .path
                }
            }
        }
        return clean
    }
}

// Add new statistics structure
struct MazeGenerationStats {
    let timeToGenerate: TimeInterval
    let deadEndCount: Int
    let averagePathLength: Double
    let branchingFactor: Double
    let symmetryScore: Double
}

@MainActor
class MazeState: ObservableObject {
    @Published var grid: [[MazeCellType]]
    @Published var currentPath: [Point] = []
    @Published var visitedCells: Set<Point> = []
    @Published var animationSpeed: Double = 0.2 // seconds between steps
    @Published var selectedAlgorithm: PathfindingAlgo = .dijkstra
    @Published var selectedMazeAlgorithm: MazeGenerationAlgo = .kruskal
    @Published var alternativePaths: [[Point]] = []
    @Published var showAlternativePaths: Bool = false
    @Published var savedMazeManager = SavedMazeManager()
    @Published var showingSavedMazes = false
    @Published var currentAnalytics: AlgorithmAnalytics?
    @Published var showingAnalytics: Bool = false
    @Published var analyticsHistory: [AlgorithmAnalytics] = []
    @Published var isEditMode: Bool = false
    @Published var isValidPath: Bool = true
    
    let size: Int
    var start: Point
    var end: Point
    
    private var currentMazeId: UUID = UUID()
    private var currentMazeStats: MazeGenerationStats?
    
    init(size: Int = 10) {
        self.size = size
        grid = Array(repeating: Array(repeating: .wall, count: size), count: size)
        start = Point(x: 1, y: 1)
        end = Point(x: size-2, y: size-2)
        generateMaze()
    }
    
    func generateMaze() {
        currentMazeId = UUID()
        switch selectedMazeAlgorithm {
        case .kruskal:
            generateKruskalMaze()
        case .prim:
            generatePrimMaze()
        case .wilson:
            generateWilsonMaze()
        case .recursiveDivision:
            generateRecursiveDivisionMaze()
        case .randomizedBraided:
            generateBraidedMaze()
        case .cellular:
            generateCellularMaze()
        case .huntAndKill:
            generateHuntAndKillMaze()
        case .spiralBacktracker:
            generateSpiralBacktrackerMaze()
        }
    }
    
    private func generatePredefinedMaze() {
        // Reset grid to all paths
        for y in 0..<size {
            for x in 0..<size {
                grid[y][x] = .path
            }
        }
        
        let walls = [
            Point(x: 1, y: 0), Point(x: 1, y: 1), Point(x: 1, y: 2),
            Point(x: 3, y: 3), Point(x: 3, y: 4), Point(x: 3, y: 5),
            Point(x: 5, y: 5), Point(x: 6, y: 5), Point(x: 7, y: 5),
            Point(x: 7, y: 2), Point(x: 7, y: 3), Point(x: 7, y: 4),
            Point(x: 1, y: 3), Point(x: 1, y: 2), Point(x: 1, y: 3),
            Point(x: 6, y: 3), Point(x: 2, y: 3), Point(x: 1, y: 1),
            Point(x: 3, y: 3), Point(x: 3, y: 3), Point(x: 1, y: 6),
            Point(x: 2, y: 3), Point(x: 2, y: 2), Point(x: 2, y: 3)
        ]
        
        for wall in walls {
            grid[wall.y][wall.x] = .wall
        }
        
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
    }
    
    private func generateKruskalMaze() {
        let startTime = Date()
        
        // Initialize grid with walls
        for y in 0..<size {
            for x in 0..<size {
                grid[y][x] = .wall
            }
        }
        
        let disjointSet = DisjointSet(size: size)
        var edges: [(from: Point, to: Point, weight: Int)] = []
        
        // Create edges between all adjacent cells with better randomization
        for y in stride(from: 1, to: size-1, by: 2) {
            for x in stride(from: 1, to: size-1, by: 2) {
                grid[y][x] = .path
                let cell = Point(x: x, y: y)
                
                // Add horizontal and vertical edges with improved weight distribution
                if x + 2 < size - 1 {
                    edges.append((
                        from: cell,
                        to: Point(x: x + 2, y: y),
                        weight: Int.random(in: 1...1000)))}
                if y + 2 < size - 1 {
                    edges.append((
                        from: cell,
                        to: Point(x: x, y: y + 2),
                        weight: Int.random(in: 1...1000)
                    ))}
            }
        }
        
        // Improved edge shuffling
        edges.shuffle()
        edges.sort { $0.weight < $1.weight }
        
        // Create the maze
        for edge in edges {
            let fromSet = disjointSet.find(edge.from)
            let toSet = disjointSet.find(edge.to)
            
            if fromSet != toSet {
                disjointSet.union(edge.from, edge.to)
                carvePathBetween(edge.from, edge.to)
            }
        }
        
        // Set start and end points
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
        
        // Validate and fix connectivity if needed
        if !validateMazeConnectivity() {
            ensureConnectivity()
        }
        
        
        let stats = MazeGenerationStats(
            timeToGenerate: Date().timeIntervalSince(startTime),
            deadEndCount: countDeadEnds(),
            averagePathLength: calculateAveragePathLength(),
            branchingFactor: calculateBranchingFactor(),
            symmetryScore: calculateSymmetryScore())
        
        currentMazeStats = stats
    }
    
    
    
    
    
    
    private func generatePrimMaze() {
        
        for y in 0..<size {
            for x in 0..<size {
                grid[y][x] = .wall
        }}
        
        var frontiers: Set<Point> = []
        var visited: Set<Point> = []
        
        
        let startCell = Point(x: 1, y: 1)
        grid[startCell.y][startCell.x] = .path
        visited.insert(startCell)
        
        // Add frontiers
        addFrontiers(from: startCell, to: &frontiers)
        
        while !frontiers.isEmpty {
            // Pick a random frontier cell
            let frontier = frontiers.randomElement()!
            frontiers.remove(frontier)
            
            // Find visited neighbors
            let neighbors = getVisitedNeighbors(of: frontier, visited: visited)
            
            if let neighbor = neighbors.randomElement() {
                // Create a passage
                grid[frontier.y][frontier.x] = .path
                let midX = (frontier.x + neighbor.x) / 2
                let midY = (frontier.y + neighbor.y) / 2
                grid[midY][midX] = .path
                
                visited.insert(frontier)
                addFrontiers(from: frontier, to: &frontiers)
            }
        }
        
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
    }
    
    private func generateWilsonMaze() {
        // Initialize all cells as walls
        for y in 0..<size {
            for x in 0..<size {
                grid[y][x] = .wall
            }
        }
        
        var unvisited = Set<Point>()
        
        for y in stride(from: 1, to: size-1, by: 2) {
            for x in stride(from: 1, to: size-1, by: 2) {
                unvisited.insert(Point(x: x, y: y))
            }
        }
        
        // Start with a random cell and mark it as part of the maze
        let firstCell = unvisited.randomElement()!
        unvisited.remove(firstCell)
        grid[firstCell.y][firstCell.x] = .path
        
        // Store the next direction for each cell during the random walk
        var nextDirection: [Point: Point] = [:]
        
        while !unvisited.isEmpty {
            // Start a new random walk from an unvisited cell
            var current = unvisited.randomElement()!
            nextDirection.removeAll()
            
            // Continue random walk until we hit a visited cell
            while grid[current.y][current.x] != .path {
                let neighbors = getValidNeighbors(of: current)
                guard let next = neighbors.randomElement() else { break }
                
                
                if let _ = nextDirection[current] {
                    var loopCell = current
                    while let nextCell = nextDirection[loopCell] {
                        nextDirection.removeValue(forKey: loopCell)
                        loopCell = nextCell
                        if loopCell == current { break }
                    }
                }
                
                nextDirection[current] = next
                current = next
            }
            
            // Carve the path from the random walk
            if !nextDirection.isEmpty {
                var pathCell = unvisited.randomElement()!
                while let next = nextDirection[pathCell] {
                    grid[pathCell.y][pathCell.x] = .path
                    // Carve the path between cells
                    grid[(pathCell.y + next.y)/2][(pathCell.x + next.x)/2] = .path
                    unvisited.remove(pathCell)
                    pathCell = next
                }
            }
        }
        
        // Ensure start and end points are accessible
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
    }

    // Helper function to get valid neighbors for Wilson's algorithm
    private func getValidNeighbors(of point: Point) -> [Point] {
        let directions = [(0, 2), (2, 0), (0, -2), (-2, 0)]
        var neighbors: [Point] = []
        
        for (dx, dy) in directions {
            let newX = point.x + dx
            let newY = point.y + dy
            
            if newX > 0 && newX < size-1 && newY > 0 && newY < size-1 {
                neighbors.append(Point(x: newX, y: newY))
            }
        }
        
        return neighbors.shuffled()
    }
        
    private func generateRecursiveDivisionMaze() {
        // Start with an empty grid
        for y in 0..<size {
            for x in 0..<size {
                grid[y][x] = .path
            }
        }
        
        // Add outer walls
        for x in 0..<size {
            grid[0][x] = .wall
            grid[size-1][x] = .wall
        }
        for y in 0..<size {
            grid[y][0] = .wall
            grid[y][size-1] = .wall
        }
        
        func divide(x: Int, y: Int, width: Int, height: Int, isHorizontal: Bool) {
            if width < 4 || height < 4 { return }
            
            let horizontal = isHorizontal || (width < height && width < 12)
            if !horizontal && (height < width && height < 12) { return }
            
            // Calculate wall position
            let wx = x + (horizontal ? 0 : Int.random(in: 1...width-2))
            let wy = y + (horizontal ? Int.random(in: 1...height-2) : 0)
            
            
            let px = wx + (horizontal ? Int.random(in: 0...width-1) : 0)
            let py = wy + (horizontal ? 0 : Int.random(in: 0...height-1))
            
            
            let dx = horizontal ? 1 : 0
            let dy = horizontal ? 0 : 1
            
            
            let length = horizontal ? width : height
            
            
            for i in 0..<length {
                let cellX = wx + (dx * i)
                let cellY = wy + (dy * i)
                if cellX != px || cellY != py {
                    
                    if Int.random(in: 0...100) < 20 { continue }
                    grid[cellY][cellX] = .wall
                }
            }
            
            // Recursively divide sub-chambers
            if horizontal {
                divide(x: x, y: y, width: width, height: wy-y, isHorizontal: !horizontal)
                divide(x: x, y: wy+1, width: width, height: height-(wy-y+1), isHorizontal: !horizontal)
            } else {
                divide(x: x, y: y, width: wx-x, height: height, isHorizontal: !horizontal)
                divide(x: wx+1, y: y, width: width-(wx-x+1), height: height, isHorizontal: !horizontal)
            }
        }
        
        divide(x: 1, y: 1, width: size-2, height: size-2, isHorizontal: Bool.random())
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
    }
        
    private func generateBraidedMaze() {
        
        generatePrimMaze()
        
        // Then remove some dead ends to create loops
        var deadEnds: [Point] = []
        
        // Find all dead ends
        for y in 1..<size-1 {
            for x in 1..<size-1 {
                let point = Point(x: x, y: y)
                if grid[y][x] == .path {
                    let neighbors = getPathNeighbors(of: point)
                    if neighbors.count == 1 {
                        deadEnds.append(point)
                    }
                }
            }
        }
        
        // Remove random dead ends to create loops
        for deadEnd in deadEnds {
            if Int.random(in: 0...100) < 50 { // 50% chance to remove each dead end
                let walls = getWallNeighbors(of: deadEnd)
                if let wallToRemove = walls.randomElement() {
                    grid[wallToRemove.y][wallToRemove.x] = .path
                }
            }
        }
    }
    
    private func generateCellularMaze() {
        // Initialize randomly but ensure start and end cells are paths
        for y in 0..<size {
            for x in 0..<size {
                // Keep the areas around start and end points more open
                let distanceToStart = abs(x - start.x) + abs(y - start.y)
                let distanceToEnd = abs(x - end.x) + abs(y - end.y)
                
                if distanceToStart <= 2 || distanceToEnd <= 2 {
                    // Create more open space near start and end points
                    grid[y][x] = Int.random(in: 0...100) < 20 ? .wall : .path
                } else {
                    // Normal random initialization for other areas
                    grid[y][x] = Int.random(in: 0...100) < 45 ? .wall : .path
                }
            }
        }
        
        // Force start and end cells to be paths
        grid[start.y][start.x] = .path
        grid[end.y][end.x] = .path
        
        // Apply cellular automata rules multiple times
        for iteration in 0..<4 {
            var newGrid = grid
            
            for y in 1..<size-1 {
                for x in 1..<size-1 {
                    
                    // Skip modifying start and end points and their immediate surroundings
                    if (abs(x - start.x) <= 1 && abs(y - start.y) <= 1) ||
                       (abs(x - end.x) <= 1 && abs(y - end.y) <= 1) {
                        continue
                    }
                    
                    let wallCount = countWallNeighbors(x: x, y: y)
                    
                    // Modified rule set to create more connected paths
                    if iteration < 2 {
                        // Initial iterations: Create wider corridors
                        newGrid[y][x] = wallCount >= 5 ? .wall : .path
                    } else {
                        // Later iterations: Refine and smooth
                        if grid[y][x] == .wall {
                            newGrid[y][x] = wallCount >= 4 ? .wall : .path
                        } else {
                            newGrid[y][x] = wallCount >= 5 ? .wall : .path
                        }
                    }
                }
            }
            grid = newGrid
        }
        
        // Ensure start and end points are properly set
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
        
        // Create a guaranteed path from start to end
        ensureConnectivity()
    }

    // Enhanced connectivity check and path creation
    private func ensureConnectivity() {
        // Find all disconnected regions and connect them
        var regions: [[Point]] = []
        var visited = Set<Point>()
        
        for y in 1..<size-1 {
            for x in 1..<size-1 {
                let point = Point(x: x, y: y)
                if grid[y][x] == .path && !visited.contains(point) {
                    var region: [Point] = []
                    var queue = [point]
                    
                    while !queue.isEmpty {
                        let current = queue.removeFirst()
                        if !visited.contains(current) {
                            visited.insert(current)
                            region.append(current)
                            
                            let neighbors = getPathNeighbors(of: current)
                            queue.append(contentsOf: neighbors)
                        }
                    }
                    
                    regions.append(region)
                }
            }
        }
        
        
        
        // Connect regions
        for i in 0..<regions.count-1 {
            let region1 = regions[i]
            let region2 = regions[i+1]
            
            var minDistance = Int.max
            var connection: (Point, Point)?
            
            for p1 in region1 {
                for p2 in region2 {
                    let distance = abs(p1.x - p2.x) + abs(p1.y - p2.y)
                    if distance < minDistance {
                        minDistance = distance
                        connection = (p1, p2)
                    }
                }
            }
            
            if let (p1, p2) = connection {
                carvePathBetween(p1, p2)
            }
        }
        
    }

    // Helper function to check if a point is within grid bounds
    private func isValidPoint(_ point: Point) -> Bool {
        point.x >= 0 && point.x < size && point.y >= 0 && point.y < size
    }
    
    private func addFrontiers(from point: Point, to frontiers: inout Set<Point>) {
        let directions = [(0, 2), (2, 0), (0, -2), (-2, 0)]
        
        for (dx, dy) in directions {
            let newX = point.x + dx
            let newY = point.y + dy
            
            if newX > 0 && newX < size-1 && newY > 0 && newY < size-1 {
                let frontier = Point(x: newX, y: newY)
                if grid[newY][newX] == .wall {
                    frontiers.insert(frontier)
                }
            }
        }
    }
    
    private func getVisitedNeighbors(of point: Point, visited: Set<Point>) -> [Point] {
        let directions = [(0, 2), (2, 0), (0, -2), (-2, 0)]
        var neighbors: [Point] = []
        
        for (dx, dy) in directions {
            let newX = point.x + dx
            let newY = point.y + dy
            
            if newX > 0 && newX < size-1 && newY > 0 && newY < size-1 {
                let neighbor = Point(x: newX, y: newY)
                if visited.contains(neighbor) {
                    neighbors.append(neighbor)
                }
            }
        }
        
        return neighbors
    }
    
    func resetPath() {
        // Clear all tracking variables
        currentPath = []
        visitedCells = []
        alternativePaths = []
        
        // Reset the entire grid except walls
        for y in 0..<size {
            for x in 0..<size {
                let point = Point(x: x, y: y)
                if point == start {
                    grid[y][x] = .start
                } else if point == end {
                    grid[y][x] = .end
                } else if grid[y][x] != .wall {
                    grid[y][x] = .path
                }
            }
        }
    }
        
    func generateNewMaze() {
        // Clear everything and generate a new maze
        currentPath = []
        visitedCells = []
        generateMaze()
    }
    
    func markVisited(_ point: Point) {
        if grid[point.y][point.x] != .start {
            grid[point.y][point.x] = .visited
        }
        visitedCells.insert(point)
    }
    
    func markPath(_ path: [Point]) {
        currentPath = path
        for point in path {
            if grid[point.y][point.x] != .start && grid[point.y][point.x] != .end {
                grid[point.y][point.x] = .current
            }
        }
    }
    
    func isWall(at point: Point) -> Bool {
        grid[point.y][point.x] == .wall
    }
    
    private func countWallNeighbors(x: Int, y: Int) -> Int {
        var count = 0
        for dy in -1...1 {
            for dx in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let newX = x + dx
                let newY = y + dy
                if newX >= 0 && newX < size && newY >= 0 && newY < size {
                    if grid[newY][newX] == .wall {
                        count += 1
                    }
                }
            }
        }
        return count
    }
        
    private func manhattanDistance(from p1: Point, to p2: Point) -> Int {
        abs(p1.x - p2.x) + abs(p1.y - p2.y)
    }
    
    private func findDirectPath(from: Point, to: Point) -> [Point] {
        var path: [Point] = []
        var current = from
        
        while current != to {
            path.append(current)
            
            // Calculate the next point based on Manhattan distance
            let dx = current.x < to.x ? 1 : (current.x > to.x ? -1 : 0)
            let dy = current.y < to.y ? 1 : (current.y > to.y ? -1 : 0)
            
            // Prefer moving in the direction with larger distance
            if abs(current.x - to.x) > abs(current.y - to.y) {
                current = Point(x: current.x + dx, y: current.y)
            } else {
                current = Point(x: current.x, y: current.y + dy)
            }
        }
        
        path.append(to)
        return path
    }
    
    private func getUnvisitedNeighbors(of point: Point) -> [Point] {
        let directions = [(0, 2), (2, 0), (0, -2), (-2, 0)]
        var neighbors: [Point] = []
        
        for (dx, dy) in directions {
            let newX = point.x + dx
            let newY = point.y + dy
            
            if newX > 0, newX < size-1, newY > 0, newY < size-1, grid[newY][newX] == .wall {
                neighbors.append(Point(x: newX, y: newY))
            }
        }
        
        return neighbors
    }

    private func getPathNeighbors(of point: Point) -> [Point] {
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        var neighbors: [Point] = []
        
        for (dx, dy) in directions {
            let newX = point.x + dx
            let newY = point.y + dy
            
            if newX >= 0, newX < size, newY >= 0, newY < size, grid[newY][newX] == .path {
                neighbors.append(Point(x: newX, y: newY))
            }
        }
        
        return neighbors
    }

    private func getWallNeighbors(of point: Point) -> [Point] {
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        var neighbors: [Point] = []
        
        for (dx, dy) in directions {
            let newX = point.x + dx
            let newY = point.y + dy
            
            if newX >= 0, newX < size, newY >= 0, newY < size, grid[newY][newX] == .wall {
                neighbors.append(Point(x: newX, y: newY))
            }
        }
        
        return neighbors
    }

    private func generateHuntAndKillMaze() {
        // Initialize grid with walls
        for y in 0..<size {
            for x in 0..<size {
                grid[y][x] = .wall
            }
        }
        
        var current = Point(x: 1, y: 1)
        grid[current.y][current.x] = .path
        
        while true {
            // Walk phase
            while let next = getUnvisitedNeighbor(current) {
                carvePathBetween(current, next)
                current = next
            }
            
            // Hunt phase
            var found = false
            huntLoop: for y in stride(from: 1, to: size-1, by: 2) {
                for x in stride(from: 1, to: size-1, by: 2) {
                    let point = Point(x: x, y: y)
                    if grid[y][x] == .wall && hasVisitedNeighbor(point) {
                        current = point
                        if let visited = getRandomVisitedNeighbor(point) {
                            carvePathBetween(current, visited)
                        }
                        found = true
                        break huntLoop
                    }
                }
            }
            
            if !found { break }
        }
        
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
    }
    
    private func generateSpiralBacktrackerMaze() {
        // Initialize grid with walls
        for y in 0..<size {
            for x in 0..<size {
                grid[y][x] = .wall
            }
        }
        
        let directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]  // Up, Right, Down, Left
        var current = Point(x: 1, y: size-2)
        var directionIndex = 0
        var stack: [Point] = [current]
        
        grid[current.y][current.x] = .path
        
        while !stack.isEmpty {
            let (dx, dy) = directions[directionIndex]
            let next = Point(x: current.x + dx*2, y: current.y + dy*2)
            
            if isValidPoint(next) && grid[next.y][next.x] == .wall {
                grid[next.y][next.x] = .path
                grid[current.y + dy][current.x + dx] = .path
                stack.append(next)
                current = next
            } else {
                // Try next direction
                directionIndex = (directionIndex + 1) % 4
                if directionIndex == 0 {
                    current = stack.removeLast()
                }
            }
        }
        
        grid[start.y][start.x] = .start
        grid[end.y][end.x] = .end
    }
    
    // Helper methods for Hunt-and-Kill
    private func getUnvisitedNeighbor(_ point: Point) -> Point? {
        let neighbors = getNeighborsForMaze(point)
        return neighbors.filter { grid[$0.y][$0.x] == .wall }.randomElement()
    }
    
    private func hasVisitedNeighbor(_ point: Point) -> Bool {
        getNeighborsForMaze(point).contains { grid[$0.y][$0.x] == .path }
    }
    
    private func getRandomVisitedNeighbor(_ point: Point) -> Point? {
        let neighbors = getNeighborsForMaze(point)
        return neighbors.filter { grid[$0.y][$0.x] == .path }.randomElement()
    }
    
    private func carvePathBetween(_ from: Point, _ to: Point) {
        grid[from.y][from.x] = .path
        grid[to.y][to.x] = .path
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        grid[midY][midX] = .path
    }
    
    private func getNeighborsForMaze(_ point: Point) -> [Point] {
        let directions = [(0, -2), (2, 0), (0, 2), (-2, 0)]  // Up, Right, Down, Left
        return directions.compactMap { dx, dy in
            let newX = point.x + dx
            let newY = point.y + dy
            guard newX > 0 && newX < size-1 && newY > 0 && newY < size-1 else { return nil }
            return Point(x: newX, y: newY)
        }
    }
    
    func createAnalytics(timeToSolve: TimeInterval, pathLength: Int, visitedCells: Set<Point>) -> AlgorithmAnalytics {
        AlgorithmAnalytics(
            mazeId: currentMazeId,
            algorithm: selectedAlgorithm,
            mazeAlgorithm: selectedMazeAlgorithm,
            timeToSolve: timeToSolve,
            pathLength: pathLength,
            cellsVisited: visitedCells.count,
            timestamp: Date(),
            visitedPoints: Array(visitedCells),
            pathPoints: currentPath,
            mazeGrid: grid
        )
    }
    
    // Add validation for maze connectivity
    private func validateMazeConnectivity() -> Bool {
        var visited = Set<Point>()
        var queue = [start]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            visited.insert(current)
            
            let neighbors = getPathNeighbors(of: current)
            for next in neighbors where !visited.contains(next) {
                queue.append(next)
            }
        }
        
        return visited.contains(end)
    }
    
    // Helper methods for maze analysis
    private func countDeadEnds() -> Int {
        var count = 0
        for y in 1..<size-1 {
            for x in 1..<size-1 {
                if grid[y][x] == .path {
                    let neighbors = getPathNeighbors(of: Point(x: x, y: y))
                    if neighbors.count == 1 {
                        count += 1
                    }
                }
            }
        }
        return count
    }
    
    private func calculateAveragePathLength() -> Double {
        return 0.0
    }
    
    private func calculateBranchingFactor() -> Double {
        var totalBranches = 0
        var intersections = 0
        
        for y in 1..<size-1 {
            for x in 1..<size-1 {
                if grid[y][x] == .path {
                    let neighbors = getPathNeighbors(of: Point(x: x, y: y))
                    if neighbors.count > 2 {
                        totalBranches += neighbors.count
                        intersections += 1
                    }
                }
            }
        }
        
        return intersections > 0 ? Double(totalBranches) / Double(intersections) : 0
    }
    
    
    private func calculateSymmetryScore() -> Double {
        var score = 0.0
        let midX = size / 2
        
        for y in 0..<size {
            for x in 0..<midX {
                if grid[y][x] == grid[y][size-1-x] {
                    score += 1
                }
                if grid[x][y] == grid[size-1-x][y] {
                    score += 1
                }
            }
        }
        
        return score / Double(size * size)
    }
}

// MARK: - Helper Classes
class DisjointSet {
    
    private var parent: [Point: Point]
    private let size: Int
    
    init(size: Int) {
        self.size = size
        self.parent = [:]
        
        // Initialize each cell as its own set
        for y in stride(from: 1, to: size-1, by: 2) {
            for x in stride(from: 1, to: size-1, by: 2) {
                let point = Point(x: x, y: y)
                parent[point] = point
            }
        }
    }
    
    func find(_ point: Point) -> Point {
        if parent[point] == point {
            return point
        }
        
        parent[point] = find(parent[point]!)
        return parent[point]!
    }
    
    
    
    func union(_ point1: Point, _ point2: Point) {
        let root1 = find(point1)
        let root2 = find(point2)
        
        if root1 != root2 {
            parent[root2] = root1
        }
    }
}
