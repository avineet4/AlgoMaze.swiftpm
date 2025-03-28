//
//  SaveMazeView.swift
//  AlgoMaze
//
//  Created by Avineet Singh on 20/02/25.
//

// SavedMazeView.swift

import SwiftUI

struct SavedMazeView: View {
    @ObservedObject var mazeManager: SavedMazeManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedMaze: SavedMaze?
    @State private var isShowingPreview = false
    var onLoadMaze: (MazeState) -> Void
    var onPreviewMaze: (SavedMaze) -> Void
    var currentMaze: MazeState
    
    var body: some View {
        NavigationView {
            List {
//                Section {
//                    // Remove the "Save Current Maze" section
//                }
                
                Section {
                    ForEach(mazeManager.savedMazes.sorted(by: { $0.timestamp > $1.timestamp })) { maze in
                        SavedMazeRow(maze: maze)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let loadedMaze = mazeManager.loadMaze(maze)
                                onLoadMaze(loadedMaze)
                                dismiss()
                            }
                            .overlay(
                                MazePreviewView(
                                    grid: maze.mazeGrid,
                                    pathPoints: maze.pathPoints.map { Point(x: $0.x, y: $0.y) },
                                    visitedPoints: Set(maze.visitedPoints.map { Point(x: $0.x, y: $0.y) }),
                                    size: maze.size
                                )
                                .frame(width: 120)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onPreviewMaze(maze)
                                    dismiss()
                                }
                                .allowsHitTesting(true),
                                alignment: .leading
                            )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let maze = mazeManager.savedMazes.sorted(by: { $0.timestamp > $1.timestamp })[index]
                            mazeManager.deleteMaze(maze)
                        }
                    }
                } header: {
                    Text("Saved Mazes")
                }
            }
            .navigationTitle("Maze Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingPreview) {
                if let maze = selectedMaze {
                    MazePreviewDetail(
                        maze: maze,
                        mazeManager: mazeManager,
                        onLoadMaze: onLoadMaze,
                        dismiss: dismiss
                    )
                }
            }
        }
    }
}

struct SavedMazeRow: View {
    let maze: SavedMaze
    
    var body: some View {
        HStack(spacing: 16) {
            MazePreviewView(
                grid: maze.mazeGrid,
                pathPoints: maze.pathPoints.map { Point(x: $0.x, y: $0.y) },
                visitedPoints: Set(maze.visitedPoints.map { Point(x: $0.x, y: $0.y) }),
                size: maze.size
            )
            .frame(width: 120) // Fixed size for consistency
            
            VStack(alignment: .leading, spacing: 12) {
                // Top section with algorithm and timestamp
                HStack(alignment: .top) {
                    Text(maze.algorithm.rawValue)
                        .font(.headline)
                    Spacer()
                    Text(maze.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Stats section
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 16) {
                        Label {
                            Text(String(format: "%.2fs", maze.timeToSolve))
                        } icon: {
                            Image(systemName: "clock")
                        }
                        
                        Label {
                            Text("\(maze.pathPoints.count)")
                        } icon: {
                            Image(systemName: "arrow.left.and.right")
                        }
                        
                        Label {
                            Text("\(maze.visitedPoints.count)")
                        } icon: {
                            Image(systemName: "eye.fill")
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                }
                
                // Generation method
                HStack {
                    Image(systemName: "cube.transparent")
                        .foregroundColor(.secondary)
                    Text(maze.mazeAlgorithm.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct MazePreviewView: View {
    let grid: [[MazeCellType]]
    let pathPoints: [Point]
    let visitedPoints: Set<Point>
    let size: Int
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<size, id: \.self) { row in
                GridRow {
                    ForEach(0..<size, id: \.self) { col in
                        let point = Point(x: col, y: row)
                        Rectangle()
                            .fill(cellColor(at: point))
                            .border(Color.black, width: 0.5)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 200) // Limit the size of the preview
    }
    
    private func cellColor(at point: Point) -> Color {
        if grid[point.y][point.x] == .wall {
            return .gray
        } else if grid[point.y][point.x] == .start {
            return .green
        } else if grid[point.y][point.x] == .end {
            return .red
        } else if pathPoints.contains(where: { $0.x == point.x && $0.y == point.y }) {
            return .yellow
        } else if visitedPoints.contains(point) {
            return .blue.opacity(0.3)
        } else {
            return .white
        }
    }
}


// shown when maze is in preview.
struct MazePreviewDetail: View {
    let maze: SavedMaze
    let mazeManager: SavedMazeManager
    let onLoadMaze: (MazeState) -> Void
    let dismiss: DismissAction
    @Environment(\.dismiss) var dismissSheet
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Large maze preview
                MazePreviewView(
                    grid: maze.mazeGrid,
                    pathPoints: maze.pathPoints.map { Point(x: $0.x, y: $0.y) },
                    visitedPoints: Set(maze.visitedPoints.map { Point(x: $0.x, y: $0.y) }),
                    size: maze.size
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding()
                
                // Stats and info
                VStack(spacing: 16) {
                    InfoRow(title: "Algorithm", value: maze.algorithm.rawValue)
                    InfoRow(title: "Generation Method", value: maze.mazeAlgorithm.rawValue)
                    InfoRow(title: "Time to Solve", value: String(format: "%.2f seconds", maze.timeToSolve))
                    InfoRow(title: "Path Length", value: "\(maze.pathPoints.count) cells")
                    InfoRow(title: "Cells Visited", value: "\(maze.visitedPoints.count) cells")
                    InfoRow(title: "Created", value: maze.timestamp.formatted(date: .long, time: .shortened))
                }
                .padding()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        dismissSheet()
                    }) {
                        Text("Close Preview")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        let loadedMaze = mazeManager.loadMaze(maze)
                        onLoadMaze(loadedMaze)
                        dismiss()
                    }) {
                        Text("Load Maze")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Maze Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
}

struct InfoRow: View {
    
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
