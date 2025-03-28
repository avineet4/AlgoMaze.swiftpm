// Views.swift

import SwiftUI
import Charts
import Combine

struct MazeView: View {
    @StateObject private var mazeState = MazeState(size: 15)
    @State private var pathFinder: PathFinder?
    @State private var isPathfinding = false
    @State private var isPaused = false
    @State private var currentTask: Task<Void, Never>?
    @State private var showingSavedMazes = false
    @State private var showingAnalytics = false
    @State private var previewMaze: SavedMaze?
    @State private var elapsedTime: TimeInterval = 0
    @State private var shouldShowTime = false
    @State private var timerSubscription: AnyCancellable?
    @State private var isDrawingWalls: Bool = true
    @GestureState private var isDragging: Bool = false
    @State private var lastDraggedPoint: Point? = nil
    
    
    
    private func startTimer() {
        stopTimer()
        elapsedTime = 0
        shouldShowTime = true
        
        timerSubscription = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if !self.isPaused {
                    self.elapsedTime += 0.01
                }
            }
    }
    
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            NavigationBarView(
                selectedAlgorithm: mazeState.selectedAlgorithm,
                selectedMazeAlgorithm: mazeState.selectedMazeAlgorithm,
                animationSpeed: $mazeState.animationSpeed,
                showingSavedMazes: $showingSavedMazes,
                visitedCount: mazeState.visitedCells.count,
                pathLength: mazeState.currentPath.count,
                isPathfinding: isPathfinding,
                isPaused: isPaused,
                isPreviewMode: previewMaze != nil,
                hasPath: !mazeState.currentPath.isEmpty,
                showTime: shouldShowTime,
                elapsedTime: elapsedTime,
                onGenerateNewMaze: {
                    previewMaze = nil
                    currentTask?.cancel()
                    isPathfinding = false
                    isPaused = false
                    stopTimer()
                    shouldShowTime = false
                    mazeState.resetPath()
                    mazeState.generateNewMaze()
                    showingAnalytics = false  // Hide analytics sheet
                    Task {
                        pathFinder = await PathFinder(maze: mazeState)
                    }
                },
                onResetPath: {
                    if isPathfinding {
                        currentTask?.cancel()
                        isPathfinding = false
                        isPaused = false
                        stopTimer()
                        shouldShowTime = false
                        Task {
                            await pathFinder?.stop()
                        }
                    } else {
                        mazeState.resetPath()
                        stopTimer()
                        shouldShowTime = false
                        Task {
                            pathFinder = await PathFinder(maze: mazeState)
                        }
                    }
                },
                onFindPath: {
                    currentTask?.cancel()
                    startTimer()
                    
                    currentTask = Task {
                        isPathfinding = true
                        isPaused = false
                        pathFinder = await PathFinder(maze: mazeState)
                        await pathFinder?.findPath()
                        if !Task.isCancelled {
                            isPathfinding = false
                            DispatchQueue.main.async {
                                stopTimer()
                                shouldShowTime = true
                            }
                        }
                    }
                },
                onTogglePause: {
                    isPaused.toggle()
                    Task {
                        await pathFinder?.togglePause(isPaused)
                    }
                },
                hasAnalytics: mazeState.currentAnalytics != nil,
                onShowAnalytics: { showingAnalytics = true },
                onSaveMaze: {
                    if let pathFinder = pathFinder {
                        Task {
                            let solveTime = await pathFinder.getCurrentSolveTime()
                            await mazeState.savedMazeManager.saveMaze(
                                mazeState,
                                timeToSolve: solveTime
                            )
                        }
                    }
                },
                onAlgorithmChange: { algorithm in
                    mazeState.selectedAlgorithm = algorithm
                },
                onMazeAlgorithmChange: { mazeAlgorithm in
                    mazeState.selectedMazeAlgorithm = mazeAlgorithm
                    mazeState.generateMaze()
                }
            )
            
            
            
            // Main Content Area with Maze Grid
            VStack(spacing: 20) {
                Spacer()
                
                // Stats display above maze
                HStack(spacing: 16) {
                    if shouldShowTime {
                        StatBadge(
                            icon: "clock",
                            value: String(format: "%.2fs", elapsedTime),
                            label: "Time",
                            color: .orange
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    StatBadge(
                        icon: "eye.fill",
                        value: "\(mazeState.visitedCells.count)",
                        label: "Visited",
                        color: .blue
                    )
                    
                    StatBadge(
                        icon: "arrow.left.and.right",
                        value: "\(mazeState.currentPath.count)",
                        label: "Path",
                        color: .yellow
                    )
                }
                .animation(.spring(response: 0.3), value: shouldShowTime)
                .animation(.spring(response: 0.3), value: mazeState.visitedCells.count)
                .animation(.spring(response: 0.3), value: mazeState.currentPath.count)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .shadow(radius: 2)
                
                if let preview = previewMaze {
                    // Show preview grid
                    Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                        ForEach(0..<preview.size, id: \.self) { row in
                            GridRow {
                                ForEach(0..<preview.size, id: \.self) { col in
                                    let point = Point(x: col, y: row)
                                    Rectangle()
                                        .fill(previewCellColor(point: point, maze: preview))
                                        .border(Color.black, width: 0.5)
                                        .animation(.easeInOut(duration: 0.3), value: preview.mazeGrid[row][col])
                                }
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding()
                    .overlay(
                        Button(action: { previewMaze = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
                } else {
                    Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                        ForEach(0..<mazeState.size, id: \.self) { row in
                            GridRow {
                                ForEach(0..<mazeState.size, id: \.self) { col in
                                    Rectangle()
                                        .fill(color(for: mazeState.grid[row][col]))
                                        .border(Color.black, width: 0.5)
                                        .animation(.easeInOut(duration: 0.3), value: mazeState.grid[row][col])
                                }
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding()
                }
                
                Spacer()
            }
            
            // Bottom Legend
            LegendView()
        }
        
        .task {
            pathFinder = await PathFinder(maze: mazeState)
        }
        .sheet(isPresented: $showingSavedMazes) {
            SavedMazeView(
                mazeManager: mazeState.savedMazeManager,
                onLoadMaze: { loadedMaze in
                    // Reset current state
                    currentTask?.cancel()
                    isPathfinding = false
                    isPaused = false
                    
                    // Update maze state
                    Task {
                        await pathFinder?.stop()
                        pathFinder = await PathFinder(maze: loadedMaze)
                    }
                },
                onPreviewMaze: { maze in
                    previewMaze = maze
                    // Update the algorithm selections to match the saved maze
                    mazeState.selectedAlgorithm = maze.algorithm
                    mazeState.selectedMazeAlgorithm = maze.mazeAlgorithm
                    // Load the maze structure
                    let loadedMaze = mazeState.savedMazeManager.loadMaze(maze)
                    // Reset current state
                    currentTask?.cancel()
                    isPathfinding = false
                    isPaused = false
                    // Update maze state
                    Task {
                        await pathFinder?.stop()
                        pathFinder = await PathFinder(maze: loadedMaze)
                    }
                },
                currentMaze: mazeState
            )
        }
        .sheet(isPresented: $showingAnalytics) {
            if let analytics = mazeState.currentAnalytics {
                AlgorithmAnalyticsView(
                    currentAnalytics: analytics,
                    history: mazeState.analyticsHistory
                )
            }
        }
        .onChange(of: mazeState.selectedAlgorithm) { _ in
            mazeState.resetPath()
            Task {
                pathFinder = await PathFinder(maze: mazeState)
            }
        }
    }
    
    
    private func previewCellColor(point: Point, maze: SavedMaze) -> Color {
        if maze.mazeGrid[point.y][point.x] == .wall {
            return .gray
        } else if maze.mazeGrid[point.y][point.x] == .start {
            return .green
        } else if maze.mazeGrid[point.y][point.x] == .end {
            return .red
        } else if maze.pathPoints.contains(where: { $0.x == point.x && $0.y == point.y }) {
            return .yellow
        } else if maze.visitedPoints.contains(where: { $0.x == point.x && $0.y == point.y }) {
            return .blue.opacity(0.3)
        } else {
            return .white
        }
    }
    
    private func color(for type: MazeCellType) -> Color {
        switch type {
        case .wall: return .gray
        case .path: return .white
        case .start: return .green.opacity(0.8)
        case .end: return .red.opacity(0.8)
        case .visited: return .blue.opacity(0.3)
        case .current: return .yellow.opacity(0.8)
        }
    }
}


//struct CellView: View {
//    let type: MazeCellType
////    let onTap: () -> Void
//    
//    var body: some View {
//        Rectangle()
//            .fill(color(for: type))
//            .border(Color.black, width: 0.5)
//            .contentShape(Rectangle())  // Make entire area tappable
////            .onTapGesture {
////                onTap()
////            }
//    }
//    
//    private func color(for type: MazeCellType) -> Color {
//        switch type {
//        case .wall: return .gray
//        case .path: return .white
//        case .start: return .green
//        case .end: return .red
//        case .visited: return .blue.opacity(0.3)
//        case .current: return .yellow
//        }
//    }
//}

struct AlgoPicker: View {
    let algorithm: PathfindingAlgo
    let mazeAlgorithm: MazeGenerationAlgo
    let onAlgorithmChange: (PathfindingAlgo) -> Void
    let onMazeAlgorithmChange: (MazeGenerationAlgo) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pathfinding Algorithm Section
            VStack(alignment: .leading, spacing: 4) {
                Label("Pathfinding", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Picker("Algorithm", selection: .init(
                    get: { algorithm },
                    set: { onAlgorithmChange($0) }
                )) {
                    ForEach(PathfindingAlgo.allCases, id: \.self) { algo in
                        Text(algo.rawValue)
                            .foregroundColor(.orange)
                            .tag(algo)
                    }
                }
                .pickerStyle(.menu)
                .tint(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Maze Generation Section
            VStack(alignment: .leading, spacing: 4) {
                Label("Generation", systemImage: "square.grid.3x3")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Picker("Maze Algorithm", selection: .init(
                    get: { mazeAlgorithm },
                    set: { onMazeAlgorithmChange($0) }
                )) {
                    ForEach(MazeGenerationAlgo.allCases, id: \.self) { algo in
                        Text(algo.rawValue)
                            .foregroundColor(.green)
                            .tag(algo)
                    }
                }
                .pickerStyle(.menu)
                .tint(.green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct SpeedControl: View {
    @Binding var animationSpeed: Double
    @State private var isHovered = false
    
    private var speedText: String {
        if animationSpeed < 0.2 { return "Very Fast" }
        if animationSpeed < 0.4 { return "Fast" }
        if animationSpeed < 0.7 { return "Normal" }
        if animationSpeed < 0.9 { return "Slow" }
        return "Very Slow"
    }
    
    private var speedColor: Color {
        if animationSpeed < 0.2 { return .green }
        if animationSpeed < 0.4 { return .blue }
        if animationSpeed < 0.7 { return .orange }
        if animationSpeed < 0.9 { return .purple }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Animation Speed")
                    .font(.subheadline)
                Spacer()
                Text(speedText)
                    .font(.caption)
                    .foregroundColor(speedColor)
                    .fontWeight(.medium)
            }
            
            HStack {
                Image(systemName: "hare.fill")
                    .foregroundColor(animationSpeed < 0.5 ? speedColor : .secondary)
                    .scaleEffect(animationSpeed < 0.5 ? 1.1 : 1.0)
                
                Slider(
                    value: $animationSpeed,
                    in: 0.05...1.0
                )
                .tint(speedColor)
                
                Image(systemName: "tortoise.fill")
                    .foregroundColor(animationSpeed >= 0.5 ? speedColor : .secondary)
                    .scaleEffect(animationSpeed >= 0.5 ? 1.1 : 1.0)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(speedColor.opacity(isHovered ? 0.15 : 0.1))
            )
            .animation(.spring(response: 0.3), value: speedColor)
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.2)) {
                isHovered = hovering
            }
        }
    }
}



struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: 16)
                .border(Color.black, width: 0.5)
            
            Text(label)
                .font(.caption)
        }
    }
}

// For interactive buttons in legend
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(isHovered ? 0.2 : 0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(color.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(color)
                .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.2)) {
                isHovered = hovering
            }
        }
    }
}


// Top bar view
struct NavigationBarView: View {
    
    let selectedAlgorithm: PathfindingAlgo
    let selectedMazeAlgorithm: MazeGenerationAlgo
    @Binding var animationSpeed: Double
    @Binding var showingSavedMazes: Bool
    let visitedCount: Int
    let pathLength: Int
    let isPathfinding: Bool
    let isPaused: Bool
    let isPreviewMode: Bool
    let hasPath: Bool
    let showTime: Bool
    let elapsedTime: TimeInterval
    let onGenerateNewMaze: () -> Void
    let onResetPath: () -> Void
    let onFindPath: () -> Void
    let onTogglePause: () -> Void
    let hasAnalytics: Bool
    let onShowAnalytics: () -> Void
    let onSaveMaze: () -> Void
    let onAlgorithmChange: (PathfindingAlgo) -> Void
    let onMazeAlgorithmChange: (MazeGenerationAlgo) -> Void
    
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                AlgoMazeLogo()
                Spacer()
            }
            .padding(.bottom, 4)
            
            HStack(alignment: .top, spacing: 20) {
                AlgoPicker(
                    algorithm: selectedAlgorithm,
                    mazeAlgorithm: selectedMazeAlgorithm,
                    onAlgorithmChange: onAlgorithmChange,
                    onMazeAlgorithmChange: onMazeAlgorithmChange
                )
                .frame(width: 250)
                
                SpeedControl(animationSpeed: $animationSpeed)
                    .frame(width: 200)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    ActionButton(
                        title: "Saved Mazes",
                        icon: "folder",
                        color: .indigo
                    ) {
                        showingSavedMazes = true
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    if hasPath {
                        ActionButton(
                            title: "Save Current Maze",
                            icon: "square.and.arrow.down",
                            color: .blue
                        ) {
                            onSaveMaze()
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    if hasAnalytics && hasPath {
                        ActionButton(
                            title: "View Analytics",
                            icon: "chart.bar.fill",
                            color: .purple
                        ) {
                            onShowAnalytics()
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: hasPath)
                .animation(.spring(response: 0.3), value: hasAnalytics)
            }
            
            HStack {
                Spacer()
                
                // Action buttons with distinct visual styles
                HStack(spacing: 12) {
                    Button(action: onGenerateNewMaze) {
                        Label("Generate New Maze", systemImage: "map")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .foregroundColor(.blue)
                    .disabled(isPathfinding)
                    
                    
                    Button(action: onResetPath) {
                        Label(isPathfinding ? "Stop" : "Reset Path",
                              systemImage: isPathfinding ? "stop.fill" : "arrow.triangle.2.circlepath")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isPathfinding ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .foregroundColor(isPathfinding ? .red : .orange)
                    
                    if isPathfinding {
                        Button(action: onTogglePause) {
                            Label(isPaused ? "Resume" : "Pause",
                                  systemImage: isPaused ? "play.fill" : "pause.fill")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .foregroundColor(.purple)
                    }
                    
                    Button(action: {
                        // First reset the path
                        onResetPath()
                        // Then find the new path
                        onFindPath()
                    }) {
                        Label("Find Path", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .foregroundColor(.green)
                    .disabled(isPathfinding)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
}


struct LegendView: View {
    @State private var hoveredItem: String? = nil
    
    let legendItems: [(color: Color, label: String, icon: String, description: String)] = [
        (.green, "Start", "play.circle.fill", "Starting point of the path"),
        (.red, "End", "flag.circle.fill", "Destination point"),
        (.gray, "Wall", "square.fill", "Obstacles that cannot be crossed"),
        (.blue.opacity(0.3), "Visited", "eye.fill", "Cells explored by the algorithm"),
        (.yellow, "Path", "arrow.right.circle.fill", "Found solution path")
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            Text("Legend:")
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(legendItems, id: \.label) { item in
                        VStack(alignment: .center, spacing: 4) {
                            Button {
                                withAnimation {
                                    hoveredItem = hoveredItem == item.label ? nil : item.label
                                }
                            } label: {
                                HStack(alignment: .center, spacing: 6) {
                                    Image(systemName: item.icon)
                                        .foregroundColor(item.color)
                                        .frame(width: 20, alignment: .center)
                                    Text(item.label)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(item.color.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if hoveredItem == item.label {
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .transition(.opacity)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(width: 120)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color.white)
        .animation(.spring(response: 0.3), value: hoveredItem)
    }
}

struct StatisticsDashboard: View {
    let analytics: [AlgorithmAnalytics]
    
    private var averageTime: Double {
        analytics.map(\.timeToSolve).reduce(0, +) / Double(analytics.count)
    }
    
    private var averagePathLength: Double {
        Double(analytics.map(\.pathLength).reduce(0, +)) / Double(analytics.count)
    }
    
    private var averageVisited: Double {
        Double(analytics.map(\.cellsVisited).reduce(0, +)) / Double(analytics.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistics Dashboard")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Avg Time",
                    value: String(format: "%.2fs", averageTime),
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg Path",
                    value: String(format: "%.1f", averagePathLength),
                    icon: "arrow.left.and.right",
                    color: .green
                )
                
                StatCard(
                    title: "Avg Visited",
                    value: String(format: "%.1f", averageVisited),
                    icon: "eye.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AlgorithmComparisonView: View {
    let analytics: [AlgorithmAnalytics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Algorithm Performance on Current Maze")
                .font(.headline)
            
           
        }
    }
}

struct AlgorithmAnalyticsView: View {
    let currentAnalytics: AlgorithmAnalytics
    let history: [AlgorithmAnalytics]
    @Environment(\.dismiss) var dismiss
    
    private var relevantAnalytics: [AlgorithmAnalytics] {
        (history + [currentAnalytics])
            .filter { $0.mazeId == currentAnalytics.mazeId }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Maze snapshot with details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Maze")
                            .font(.headline)
                        
                        // Maze details
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Generation: \(currentAnalytics.mazeAlgorithm.rawValue)",
                                  systemImage: "map")
                                .foregroundColor(.blue)
                            Label("Solver: \(currentAnalytics.algorithm.rawValue)",
                                  systemImage: "arrow.triangle.turn.up.right.diamond")
                                .foregroundColor(.purple)
                            Label(String(format: "Time: %.2fs", currentAnalytics.timeToSolve),
                                  systemImage: "clock")
                                .foregroundColor(.orange)
                        }
                        .padding(.bottom, 8)
                        
                        // Maze snapshot grid
                        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                            ForEach(0..<currentAnalytics.cleanMazeGrid.count, id: \.self) { row in
                                GridRow {
                                    ForEach(0..<currentAnalytics.cleanMazeGrid[row].count, id: \.self) { col in
                                        Rectangle()
                                            .fill(cellColor(type: currentAnalytics.cleanMazeGrid[row][col],
                                                          point: Point(x: col, y: row)))
                                            .frame(width: 8, height: 8)
                                            .border(Color.black, width: 0.2)
                                    }
                                }
                            }
                        }
                        .frame(width: 200, height: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    StatisticsDashboard(analytics: relevantAnalytics)
                    
                    AlgorithmComparisonView(analytics: relevantAnalytics)
                    
                    // Performance Metrics Chart
                    ChartSection(
                        title: "Algorithm Performance",
                        analytics: relevantAnalytics
                    )
                    
                    // Efficiency Comparison
                    EfficiencySection(
                        title: "Efficiency Metrics",
                        analytics: relevantAnalytics
                    )
                    
                    // Current Run Details
                    Section("Current Run") {
                        AnalyticsRow(
                            analytics: currentAnalytics,
                            isCurrentRun: true,
                            bestTime: bestTimeForMaze,
                            bestPath: bestPathLength
                        )
                    }
                    
                    // Historical Data
                    if relevantAnalytics.count > 1 {
                        HistoricalSection(
                            title: "Historical Comparison",
                            analytics: relevantAnalytics,
                            currentRun: currentAnalytics
                        )
                    }
                    
                    // Add Complexity Information
                    AlgorithmComplexityView(algorithm: currentAnalytics.algorithm)
                }
                .padding()
            }
            .navigationTitle("Maze Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private var bestTimeForMaze: TimeInterval {
        relevantAnalytics.map { $0.timeToSolve }.min() ?? currentAnalytics.timeToSolve
    }
    
    private var bestPathLength: Int {
        relevantAnalytics.map { $0.pathLength }.min() ?? currentAnalytics.pathLength
    }
    
    private func cellColor(type: MazeCellType, point: Point) -> Color {
        switch type {
        case .wall: return .gray
        case .start: return .green
        case .end: return .red
        case .path, .visited, .current: return .white
        }
    }
}

struct ChartSection: View {
    let title: String
    let analytics: [AlgorithmAnalytics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            Text("This chart shows the solve time for each algorithm run on this maze. Lower times indicate better performance.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(analytics, id: \.timestamp) { analytic in
                    BarMark(
                        x: .value("Algorithm", analytic.algorithm.rawValue),
                        y: .value("Time", analytic.timeToSolve)
                    )
                    .foregroundStyle(by: .value("Algorithm", analytic.algorithm.rawValue))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct EfficiencySection: View {
    let title: String
    let analytics: [AlgorithmAnalytics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            Text("This scatter plot compares the number of cells visited vs the final path length. More efficient algorithms will have fewer visited cells (x-axis) while maintaining shorter path lengths (y-axis).")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(analytics, id: \.timestamp) { analytic in
                    LineMark(
                        x: .value("Visited", analytic.cellsVisited),
                        y: .value("Path Length", analytic.pathLength)
                    )
                    .foregroundStyle(by: .value("Algorithm", analytic.algorithm.rawValue))
                    
                    PointMark(
                        x: .value("Visited", analytic.cellsVisited),
                        y: .value("Path Length", analytic.pathLength)
                    )
                    .foregroundStyle(by: .value("Algorithm", analytic.algorithm.rawValue))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct HistoricalSection: View {
    let title: String
    let analytics: [AlgorithmAnalytics]
    let currentRun: AlgorithmAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            Text("This timeline shows how solve times have changed across different runs. Lower points indicate faster solutions. Compare different algorithms to see which performs best over time.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            Chart {
                ForEach(analytics, id: \.timestamp) { analytic in
                    LineMark(
                        x: .value("Time", analytic.timestamp),
                        y: .value("Solve Time", analytic.timeToSolve)
                    )
                    .foregroundStyle(by: .value("Algorithm", analytic.algorithm.rawValue))
                    
                    PointMark(
                        x: .value("Time", analytic.timestamp),
                        y: .value("Solve Time", analytic.timeToSolve)
                    )
                    .foregroundStyle(by: .value("Algorithm", analytic.algorithm.rawValue))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct AnalyticsRow: View {
    let analytics: AlgorithmAnalytics
    let isCurrentRun: Bool
    let bestTime: TimeInterval
    let bestPath: Int
    
    private var timeComparison: String {
        let diff = analytics.timeToSolve - bestTime
        if diff == 0 { return " (Fastest)" }
        return String(format: " (+%.2fs)", diff)
    }
    
    private var pathComparison: String {
        let diff = analytics.pathLength - bestPath
        if diff == 0 { return " (Shortest)" }
        return " (+\(diff))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(analytics.algorithm.rawValue)
                    .font(.headline)
                if isCurrentRun {
                    Text("(Current)")
                        .foregroundColor(.blue)
                        .italic()
                }
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Time: \(String(format: "%.2fs", analytics.timeToSolve))")
                        Text(timeComparison)
                            .foregroundColor(analytics.timeToSolve == bestTime ? .green : .secondary)
                            .italic()
                    }
                    HStack {
                        Text("Path: \(analytics.pathLength)")
                        Text(pathComparison)
                            .foregroundColor(analytics.pathLength == bestPath ? .green : .secondary)
                            .italic()
                    }
                }
                Spacer()
                Text("Visited: \(analytics.cellsVisited)")
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            if !isCurrentRun {
                Text(analytics.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AlgorithmComplexityView: View {
    let algorithm: PathfindingAlgo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Complexity Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Time & Space Complexity")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    ComplexityCard(
                        title: "Time",
                        value: algorithm.complexity.time,
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    ComplexityCard(
                        title: "Space",
                        value: algorithm.complexity.space,
                        icon: "memorychip",
                        color: .green
                    )
                }
            }
            
            // Explanation Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Explanation")
                    .font(.headline)
                Text(algorithm.complexityExplanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct ComplexityCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: isHovered ? 16 : 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption)
                    .opacity(0.8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(isHovered ? 0.2 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        )
        .foregroundColor(color)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var isShowingOnboarding = true
    
    var body: some View {
        TabView {
            MazeView()
                .tabItem {
                    Label("Visualizer", systemImage: "map")
                }
            
            AlgorithmLearningView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView(isShowingOnboarding: $isShowingOnboarding)
        }
        .onAppear {
            if !hasSeenOnboarding {
                isShowingOnboarding = true
                hasSeenOnboarding = true
            }
        }
    }
}

struct AlgorithmLearningView: View {
    var body: some View {
        NavigationView {
            List {
                Section("About AlgoMaze") {
                    NavigationLink(destination: AboutAlgoMazeView()) {
                        Label("Introduction", systemImage: "info.circle")
                    }
                }
                
                Section("Pathfinding Algorithms") {
                    ForEach(PathfindingAlgo.allCases, id: \.self) { algorithm in
                        NavigationLink(destination: AlgorithmDetailView(algorithm: algorithm)) {
                            Label(algorithm.rawValue, systemImage: "arrow.triangle.turn.up.right.diamond")
                        }
                    }
                }
                
                Section("Maze Generation") {
                    ForEach(MazeGenerationAlgo.allCases, id: \.self) { algorithm in
                        NavigationLink(destination: MazeAlgorithmDetailView(algorithm: algorithm)) {
                            Label(algorithm.rawValue, systemImage: "square.grid.3x3")
                        }
                    }
                }
            }
            .navigationTitle("Learn Algorithms")
            
            // Default view when no item is selected
            AboutAlgoMazeView()
        }
    }
}

struct AboutAlgoMazeView: View {
    @State private var selectedSection: Int = 0
    @State private var isAuthorCardHovered = false
    @State private var selectedPurpose: String?
    
    private let sections = [
        "About": """
            AlgoMaze is an interactive educational tool designed to visualize and understand pathfinding algorithms and maze generation techniques. It brings complex computer science concepts to life through real-time visualization, making learning both engaging and intuitive.
            
            The app features:
            • 9 different pathfinding algorithms
            • 8 maze generation techniques
            • Real-time visualization
            • Performance analytics
            • Interactive learning tools
            """,
        
        "How to Use": "",
        
        "Developer's Note": """
            As a competitive programmer, I excelled at implementing algorithms to solve complex problems. However, during a crucial competition, I had an eye-opening moment - while I could code these algorithms, I didn't truly understand how they worked at their core. This realization helped me identify a widespread challenge in computer science education: students often memorize algorithms without grasping their fundamental behavior.

            The human brain processes visual information 60,000 times faster than text, yet most algorithm education relies heavily on textbooks and static diagrams. Many of us can write the code, but struggle to visualize how these algorithms actually make decisions. Seeing an algorithm in action - watching it explore paths, make decisions, and sometimes even make mistakes - creates deeper, more intuitive understanding than any textbook explanation.

            This inspired me to create AlgoMaze, transforming abstract pathfinding concepts into visual, interactive experiences. By visualizing each step of the algorithm's decision-making process, students can build mental models that stick. The app aims to bridge the gap between theoretical knowledge and practical understanding, not just for me, but for every student learning these essential computer science concepts.
            """
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                VStack(spacing: 16) {
                    AlgoMazeLogo()
                        .scaleEffect(1.2)
                    
                    Text("Visualize. Learn. Understand.")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    AuthorCard(isHovered: $isAuthorCardHovered)
                        .padding(.top, 8)
                }
                .padding(.vertical, 20)
                
                
                Picker("Section", selection: $selectedSection) {
                    Text("About").tag(0)
                    Text("How to Use").tag(1)
                    Text("Developer").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedSection {
                    case 0:
                        AboutSection(content: sections["About"]!)
                    case 1:
                        HowToUseSection()
                    case 2:
                        DeveloperSection(content: sections["Developer's Note"]!)
                    default:
                        EmptyView()
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                .animation(.spring(), value: selectedSection)
            }
            .padding()
        }
        .navigationTitle("About AlgoMaze")
    }
}

struct AboutSection: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About AlgoMaze")
                .font(.title2.bold())
                .foregroundColor(.blue)
            
            Text(content)
                .foregroundColor(.secondary)
        }
    }
}

struct DeveloperSection: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Developer's Note")
                .font(.title2.bold())
                .foregroundColor(.blue)
            
            Text(content)
                .foregroundColor(.secondary)
        }
    }
}

struct HowToUseSection: View {
    let features: [(icon: String, title: String, description: String)] = [
        ("arrow.triangle.turn.up.right.diamond", 
         "Algorithm Selection",
         "Select different pathfinding algorithms like A*, Dijkstra, or BFS to solve the maze"),
        
        ("square.grid.3x3",
         "Maze Generation",
         "Choose different maze generation methods to create unique maze patterns"),
        
        ("slider.horizontal.3",
         "Speed Control",
         "Control the visualization speed - slide left for faster animation, right for slower"),
        
        ("map",
         "Generate Maze",
         "Create a new maze using the selected generation algorithm"),
        
        ("play.fill",
         "Find Path",
         "Start the pathfinding algorithm to find a route from start to end"),
        
        ("arrow.counterclockwise",
         "Reset Path",
         "Clear the current path and visited cells to try a different approach"),
        
        ("clock.fill",
         "Statistics",
         "Monitor solve time, visited cells, and final path length in real-time"),
        
        ("chart.bar.fill",
         "Analytics",
         "Compare performance metrics and analyze algorithm efficiency"),
        
        ("square.and.arrow.down",
         "Save Maze",
         "Store interesting mazes and solutions for later reference"),
        
        ("folder.fill",
         "Saved Mazes",
         "Access your collection of saved mazes and solutions"),
        
        ("list.bullet",
         "Legend",
         "Understand different cell colors and their meanings in the visualization")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Use AlgoMaze")
                .font(.title2.bold())
                .foregroundColor(.blue)
            
            Text("Learn about the different features and controls available in the visualizer")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            LazyVStack(spacing: 16) {
                ForEach(features, id: \.title) { feature in
                    FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description
                    )
                }
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            
            if isExpanded {
                
                DemoView(title: title)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}

struct DemoView: View {
    let title: String
    
    var body: some View {
        VStack {
            switch title {
            case "Algorithm Selection":
                AlgoPicker(
                    algorithm: .aStar,
                    mazeAlgorithm: .recursiveDivision,
                    onAlgorithmChange: { _ in },
                    onMazeAlgorithmChange: { _ in }
                )
                
            case "Maze Generation":
                AlgoPicker(
                    algorithm: .aStar,
                    mazeAlgorithm: .recursiveDivision,
                    onAlgorithmChange: { _ in },
                    onMazeAlgorithmChange: { _ in }
                )
                
            case "Speed Control":
                SpeedControl(animationSpeed: .constant(0.5))
                
            case "Generate Maze":
                ActionButton(
                    title: "Generate New Maze",
                    icon: "map",
                    color: .blue,
                    action: {}
                )
                
            case "Find Path":
                ActionButton(
                    title: "Find Path",
                    icon: "play.fill",
                    color: .green,
                    action: {}
                )
                
            case "Reset Path":
                ActionButton(
                    title: "Reset Path",
                    icon: "arrow.counterclockwise",
                    color: .orange,
                    action: {}
                )
                
            case "Statistics":
                VStack(spacing: 16) {
                    Text("Real-time Statistics")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        StatBadge(icon: "clock", value: "1.23s", label: "Time", color: .orange)
                        StatBadge(icon: "eye.fill", value: "150", label: "Visited", color: .blue)
                        StatBadge(icon: "arrow.left.and.right", value: "25", label: "Path", color: .yellow)
                    }
                }
                
            case "Analytics":
                VStack(spacing: 8) {
                    Text("Performance Analytics")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 30))
                            Text("Performance")
                                .font(.caption)
                        }
                        
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 30))
                            Text("Efficiency")
                                .font(.caption)
                        }
                        
                        VStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 30))
                            Text("History")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.purple)
                }
                
            case "Save Maze":
                ActionButton(
                    title: "Save Current Maze",
                    icon: "square.and.arrow.down",
                    color: .blue,
                    action: {}
                )
                
            case "Saved Mazes":
                VStack(spacing: 8) {
                    Text("Saved Mazes")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "square.grid.3x3")
                                        .foregroundColor(.blue)
                                )
                        }
                    }
                }
                
            case "Legend":
                HStack(spacing: 16) {
                    LegendItem(color: .green, label: "Start")
                    LegendItem(color: .red, label: "End")
                    LegendItem(color: .gray, label: "Wall")
                    LegendItem(color: .blue.opacity(0.3), label: "Visited")
                    LegendItem(color: .yellow, label: "Path")
                }
                
            default:
                Text("Feature demonstration")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}


struct OnboardingScreen: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let image: String
    let color: Color
}


struct OnboardingView: View {
    @Binding var isShowingOnboarding: Bool
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    private let pages = [
        OnboardingScreen(
            title: "Welcome to AlgoMaze",
            description: "An interactive way to learn and visualize pathfinding algorithms and maze generation techniques.",
            image: "map.fill",
            color: .orange
        ),
        OnboardingScreen(
            title: "Choose Your Algorithms",
            description: "Select from various pathfinding algorithms and maze generation techniques to see how they work.",
            image: "arrow.triangle.turn.up.right.diamond.fill",
            color: .green
        ),
        OnboardingScreen(
            title: "Watch It in Action",
            description: "Visualize how algorithms explore the maze and find the optimal path in real-time.",
            image: "play.fill",
            color: .blue
        ),
        OnboardingScreen(
            title: "Analyze Performance",
            description: "Compare different algorithms and analyze their performance with detailed analytics.",
            image: "chart.bar.fill",
            color: .purple
        ),
        OnboardingScreen(
            title: "Learn and Experiment",
            description: "Access detailed explanations and experiment with different maze configurations.",
            image: "book.fill",
            color: .indigo
        )
    ]
    
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [.white, Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // custom algomaze logo
                AlgoMazeLogo()
                    .scaleEffect(1.2)
                    .padding(.top, 40)
                
                // page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], isAnimating: isAnimating)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)
                
                // Navigation Buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: { withAnimation { currentPage -= 1 } }) {
                            Label("Previous", systemImage: "chevron.left")
                                .foregroundColor(pages[currentPage].color)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(pages[currentPage].color.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            Label("Next", systemImage: "chevron.right")
                                .foregroundColor(pages[currentPage].color)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(pages[currentPage].color.opacity(0.1))
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            withAnimation(.spring()) {
                                isShowingOnboarding = false
                            }
                        }) {
                            Text("Get Started")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(pages[currentPage].color)
                                .cornerRadius(10)
                                .shadow(color: pages[currentPage].color.opacity(0.3), radius: 5)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                // Skip Button
                if currentPage < pages.count - 1 {
                    Button(action: {
                        withAnimation(.spring()) {
                            isShowingOnboarding = false
                        }
                    }) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingScreen
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 35) {
            Image(systemName: page.image)
                .font(.system(size: 90))
                .foregroundColor(page.color)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true), value: isAnimating)
            
            Text(page.title)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isAnimating)
            
            Text(page.description)
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isAnimating)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 20)
    }
    
}


struct AlgoMazeLogo: View {
    @State private var isAnimating = false
    let gridSize = 5
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                // Maze icon
                ZStack {
                    // Background maze pattern
                    Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                        ForEach(0..<gridSize, id: \.self) { row in
                            GridRow {
                                ForEach(0..<gridSize, id: \.self) { col in
                                    Rectangle()
                                        .fill(shouldBeWall(row: row, col: col) ?
                                              Color.blue.opacity(0.3) : Color.clear)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                    
                    // Animated path
                    Path { path in
                        path.move(to: CGPoint(x: 4, y: 4))
                        path.addLine(to: CGPoint(x: 36, y: 4))
                        path.addLine(to: CGPoint(x: 36, y: 36))
                        path.addLine(to: CGPoint(x: 4, y: 36))
                    }
                    .trim(from: 0, to: isAnimating ? 1 : 0)
                    .stroke(Color.blue, lineWidth: 2)
                }
                .frame(width: 40, height: 40)
                
                // App name
                Text("AlgoMaze")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }
            
            // Tagline
            Text("Pathfinding Visualized")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func shouldBeWall(row: Int, col: Int) -> Bool {
        return (row % 2 == 0) || (col % 2 == 0)
    }
}

// Preview of logo for test purpose
//struct AlgoMazeLogo_Previews: PreviewProvider {
//    static var previews: some View {
//        AlgoMazeLogo()
//            .padding()
//            .previewLayout(.sizeThatFits)
//    }
//}

struct AlgorithmDetailView: View {
    let algorithm: PathfindingAlgo
    @State private var selectedSection: String? = nil
    
    var body: some View {
        ScrollView {
        VStack(spacing: 24) {
                // Algorithm Title
                Text(algorithm.rawValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .padding(.bottom)
                
                // Interactive Section Cards
            VStack(spacing: 16) {
                    // Overview Section
                    DetailCard(
                        title: "Overview",
                        icon: "info.circle",
                        content: algorithm.description,
                        isExpanded: selectedSection == "overview",
                        onTap: { selectedSection = selectedSection == "overview" ? nil : "overview" }
                    )
                    
                    // Complexity Section
                AlgorithmComplexityView(algorithm: algorithm)
                    
                    // How It Works Section
                    DetailCard(
                        title: "How It Works",
                        icon: "gearshape.2",
                        content: algorithm.AlgoWorking,
                        isExpanded: selectedSection == "howItWorks",
                        onTap: { selectedSection = selectedSection == "howItWorks" ? nil : "howItWorks" }
                    )
                    
                    // Use Cases Section
                    DetailCard(
                        title: "Use Cases",
                        icon: "briefcase",
                        content: algorithm.uses,
                        isExpanded: selectedSection == "useCases",
                        onTap: { selectedSection = selectedSection == "useCases" ? nil : "useCases" }
                    )
                }
            }
        }
    }
}

struct MazeAlgorithmDetailView: View {
    let algorithm: MazeGenerationAlgo
    @State private var selectedSection: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Algorithm Title
                Text(algorithm.rawValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                    .padding(.bottom)
                
                // Interactive Section Cards
                VStack(spacing: 16) {
                    // Overview Section
                    DetailCard(
                        title: "Overview",
                        icon: "info.circle",
                        content: algorithm.description,
                        isExpanded: selectedSection == "overview",
                        onTap: { selectedSection = selectedSection == "overview" ? nil : "overview" }
                    )
                    
                    // Properties Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Properties")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            PropertyCard(
                                title: "Multiple Paths",
                                value: algorithm.allowsMultiplePaths ? "Yes" : "No",
                                icon: "arrow.triangle.branch",
                                color: .purple
                            )
                            
                            PropertyCard(
                                title: "Bias",
                                value: algorithm.hasBias ? "Yes" : "No",
                                icon: "arrow.up.and.down.and.arrow.left.and.right",
                                color: .orange
                            )
                        }
                        
                        PropertyCard(
                            title: "Generation Style",
                            value: algorithm.generationStyle,
                            icon: "wand.and.stars",
                            color: .blue
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // How It Works Section
                    DetailCard(
                        title: "How It Works",
                        icon: "gearshape.2",
                        content: algorithm.howItWorks,
                        isExpanded: selectedSection == "howItWorks",
                        onTap: { selectedSection = selectedSection == "howItWorks" ? nil : "howItWorks" }
                    )
                    
                    // Characteristics Section
                    DetailCard(
                        title: "Characteristics",
                        icon: "chart.bar.fill",
                        content: algorithm.characteristics,
                        isExpanded: selectedSection == "characteristics",
                        onTap: { selectedSection = selectedSection == "characteristics" ? nil : "characteristics" }
                    )
                    
                }
            }
        }
        
    }
}


struct AuthorCard: View {
    @Binding var isHovered: Bool
    @State private var selectedSection: AuthorSection? = nil
    
    enum AuthorSection: String {
        case education = "Education"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Author Header
            HStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: isHovered ? 60 : 50))
                    .foregroundColor(.blue)
                    .animation(.spring(), value: isHovered)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Avineet Singh Juneja")
                        .font(.title3.bold())
                    Text("Student Developer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Faridabad, Haryana, India")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(isHovered ? 0.15 : 0.1))
            )
            
            // Section Button
            Button(action: {
                withAnimation(.spring()) {
                    selectedSection = selectedSection == .education ? nil : .education
                }
            }) {
                Text("Education")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedSection == .education ? 
                                 Color.blue : Color.blue.opacity(0.1))
                    )
                    .foregroundColor(selectedSection == .education ? .white : .blue)
            }
            
            // Education Content
            if selectedSection == .education {
                EducationView()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: isHovered ? 8 : 4)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring()) {
                isHovered = hovering
            }
        }
    }
}

// Supporting Views
extension AuthorCard.AuthorSection: CaseIterable {}

struct EducationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Galgotias University, Greater Noida", systemImage: "building.columns.fill")
                .font(.headline)
            Text("B.Tech in Computer Science & Engineering")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Specialization in AI & ML (2022-2026)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}


struct PropertyCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}


struct DetailCard: View {
    let title: String
    let icon: String
    let content: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isExpanded ? 360 : 0))
                    
                    Text(title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(content)
                    .foregroundColor(.secondary)
                    .padding(.leading)
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .animation(.spring(), value: isExpanded)
    }
}

