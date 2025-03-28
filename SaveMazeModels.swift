//
//  SaveMazeModels.swift
//  AlgoMaze
//
//  Created by Avineet Singh on 20/02/25.
//

// Saving Maze Models

import Foundation

// Represents a saved maze state that can be stored and loaded
struct SavedMaze: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let algorithm: PathfindingAlgo
    let mazeAlgorithm: MazeGenerationAlgo
    let size: Int
    let mazeGrid: [[MazeCellType]]
    let pathPoints: [Point]
    let visitedPoints: [Point]
    let timeToSolve: TimeInterval
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        algorithm: PathfindingAlgo,
        mazeAlgorithm: MazeGenerationAlgo = .kruskal,
        size: Int,
        mazeGrid: [[MazeCellType]],
        pathPoints: [Point],
        visitedPoints: [Point],
        timeToSolve: TimeInterval
    ) {
        self.id = id
        self.timestamp = timestamp
        self.algorithm = algorithm
        self.mazeAlgorithm = mazeAlgorithm
        self.size = size
        self.mazeGrid = mazeGrid
        self.pathPoints = pathPoints
        self.visitedPoints = visitedPoints
        self.timeToSolve = timeToSolve
    }
}


// Make CellType codable for storage
extension MazeCellType: Codable {
    enum CodingKeys: String, CodingKey {
        case wall, path, start, end, visited, current
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .wall: try container.encode("wall")
        case .path: try container.encode("path")
        case .start: try container.encode("start")
        case .end: try container.encode("end")
        case .visited: try container.encode("visited")
        case .current: try container.encode("current")
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "wall": self = .wall
        case "path": self = .path
        case "start": self = .start
        case "end": self = .end
        case "visited": self = .visited
        case "current": self = .current
        default: self = .path
        }
    }
}

// First, make the PathfindingAlgorithm and MazeGenerationAlgorithm enums Codable
extension PathfindingAlgo: Codable {
    enum CodingKeys: String, CodingKey {
        case dijkstra, aStar, bfs, dfs, bidirectional, bestFirst, idaStar, fringe, theta
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if let algorithm = PathfindingAlgo(rawValue: value) {
            self = algorithm
        } else {
            self = .aStar // Default value
        }
    }
}

extension MazeGenerationAlgo: Codable {
    enum CodingKeys: String, CodingKey {
        case kruskal, prim, wilson, recursiveDivision, randomizedBraided, cellular, huntAndKill, spiralBacktracker
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        if let algorithm = MazeGenerationAlgo(rawValue: value) {
            self = algorithm
        } else {
            self = .kruskal // Default value changed from .custom to .kruskal
        }
    }
}

// Manages the persistence of maze states
@MainActor
class SavedMazeManager: ObservableObject {
    // Currently loaded saved mazes
    @Published private(set) var savedMazes: [SavedMaze] = []
    private let savePath: URL
    private let currentVersion = 1
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        savePath = documentsPath.appendingPathComponent("savedMazes.json")
        loadSavedMazes()
    }
    
    // Saves a maze state with its solution time
    // - Parameters:
    //   - maze: The maze state to save
    //   - timeToSolve: Time taken to solve the maze
    func saveMaze(_ maze: MazeState, timeToSolve: TimeInterval) async {
        let savedMaze = await SavedMaze(maze: maze, timeToSolve: timeToSolve)
        savedMazes.append(savedMaze)
        saveToDisk()
    }
    
    func deleteMaze(_ maze: SavedMaze) {
        savedMazes.removeAll { $0.id == maze.id }
        saveToDisk()
    }
    
    func loadMaze(_ saved: SavedMaze) -> MazeState {
        let maze = MazeState(size: saved.size)
        
        // Load the basic maze structure
        maze.grid = saved.mazeGrid
        
        // Convert SavedMaze.SavedPoint to app's Point type and set the path
        maze.currentPath = saved.pathPoints.map { Point(x: $0.x, y: $0.y) }
        
        // Set visited cells
        maze.visitedCells = Set(saved.visitedPoints.map { Point(x: $0.x, y: $0.y) })
        
        // Update the grid to show the path and visited cells
        for point in maze.visitedCells {
            if maze.grid[point.y][point.x] != .start && maze.grid[point.y][point.x] != .end {
                maze.grid[point.y][point.x] = .visited
            }
        }
        
        for point in maze.currentPath {
            if maze.grid[point.y][point.x] != .start && maze.grid[point.y][point.x] != .end {
                maze.grid[point.y][point.x] = .current
            }
        }
        
        // Set algorithms
        maze.selectedAlgorithm = saved.algorithm
        maze.selectedMazeAlgorithm = saved.mazeAlgorithm
        
        return maze
    }
    
    private func loadSavedMazes() {
        do {
            let data = try Data(contentsOf: savePath)
            let decoder = JSONDecoder()
            
            // Check version and migrate if needed
            if let version = try? decoder.decode(Int.self, from: data) {
                savedMazes = try migrateData(data: data, fromVersion: version)
            } else {
                // Handle legacy data
                savedMazes = try decoder.decode([SavedMaze].self, from: data)
            }
        } catch {
            print("Error loading saved mazes: \(error)")
            savedMazes = []
        }
    }
    
    private func migrateData(data: Data, fromVersion: Int) throws -> [SavedMaze] {
        // Add migration logic for future versions
        switch fromVersion {
        case currentVersion:
            return try JSONDecoder().decode([SavedMaze].self, from: data)
        default:
            throw SavedMazeError.unsupportedVersion
        }
    }
    
    
    // for data persistence
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(savedMazes)
            try data.write(to: savePath)
        } catch {
            print("Error saving mazes to disk: \(error)")
        }
    }
    
    // Add convenience methods for sorting and filtering
    func getMazesSortedByDate() -> [SavedMaze] {
        savedMazes.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getMazesSortedByTime() -> [SavedMaze] {
        savedMazes.sorted { $0.timeToSolve < $1.timeToSolve }
    }
    
    func getMazes(forAlgorithm algorithm: PathfindingAlgo) -> [SavedMaze] {
        savedMazes.filter { $0.algorithm == algorithm }
    }
}

// Add custom error types
enum SavedMazeError: Error {
    case invalidTimeToSolve
    case invalidGrid
    case invalidPath
    case unsupportedVersion
}

// Add initializer for SavedMaze from MazeState
extension SavedMaze {
    init(maze: MazeState, timeToSolve: TimeInterval) async {
        self.id = UUID()
        self.timestamp = Date()
        self.size = maze.size
        self.mazeGrid = await maze.grid
        self.pathPoints = await maze.currentPath
        self.visitedPoints = await Array(maze.visitedCells)
        self.timeToSolve = timeToSolve
        self.algorithm = await maze.selectedAlgorithm
        self.mazeAlgorithm = await maze.selectedMazeAlgorithm
    }
}
