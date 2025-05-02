import SwiftUI
import AVFoundation

struct ContentView: View {
    let gridSize = 5 // Defines the grid as 5x5

    // State variables to track the game's state
    @State private var tappedCells: [[Bool]] // Marks which cells the user has tapped
    @State private var revealedCells: [[Bool]] // Marks which cells are currently visible (can be tapped)
    @State private var tapOrder: [[Int?]] // Stores the order in which each cell was tapped
    @State private var sequence: [(row: Int, col: Int)] = [] // Random sequence of cells to be activated
    @State private var currentIndex = 0 // Index of the currently active cell in the sequence
    @State private var tapCounter = 1 // Tracks tap order (starts from 1)
    @State private var activeCell: (row: Int, col: Int)? = nil // Currently active cell coordinates
    @State private var gameStarted = false // Flag to indicate if the game has started
    @State private var showSummary = false // Flag to indicate if the game summary screen should be shown
    @State private var audioPlayer: AVAudioPlayer? // Player for the beep sound

    // Initialize the 2D arrays with default values
    init() {
        _tappedCells = State(initialValue: Array(repeating: Array(repeating: false, count: 5), count: 5))
        _revealedCells = State(initialValue: Array(repeating: Array(repeating: false, count: 5), count: 5))
        _tapOrder = State(initialValue: Array(repeating: Array(repeating: nil, count: 5), count: 5))
    }

    var body: some View {
        VStack {
            if showSummary {
                // Show summary screen with a "Start Again" button
                Button("Start Again") {
                    resetGame()
                    gameStarted = true
                    generateRandomSequence()
                    startSequence()
                }
                .padding(.top, 20)
            } else if !gameStarted {
                // Show the initial "Start" button
                Button("Start") {
                    resetGame()
                    gameStarted = true
                    generateRandomSequence()
                    startSequence()
                }
                .font(.title)
                .padding()
            } else {
                // Display the game grid
                VStack(spacing: 0) {
                    ForEach(0..<gridSize, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<gridSize, id: \.self) { col in
                                Button(action: {
                                    handleTap(row: row, col: col)
                                }) {
                                    Rectangle()
                                        .frame(width: 35, height: 35)
                                        .foregroundColor(getCellColor(row: row, col: col))
                                        .opacity(revealedCells[row][col] ? 1.0 : 0.0) // Only show if revealed
                                        .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
                                }
                                .background(Color.black)
                                .buttonStyle(BorderlessButtonStyle())
                                .disabled(!revealedCells[row][col] || activeCell?.row != row || activeCell?.col != col)
                                // Disable button if cell is not revealed or not the active one
                            }
                        }
                    }
                }
                .padding(.bottom, 17)
            }
        }
        .padding()
    }

    // Generates a random sequence of all cells in the grid
    func generateRandomSequence() {
        let allCells = (0..<gridSize).flatMap { row in
            (0..<gridSize).map { col in (row, col) }
        }
        sequence = allCells.shuffled() // Randomize order
    }

    // Starts showing the sequence from the beginning
    func startSequence() {
        currentIndex = 0
        showNextCell()
    }

    // Reveals the next cell in the sequence
    func showNextCell() {
        guard currentIndex < sequence.count else {
            activeCell = nil // No more cells to show
            return
        }

        let cell = sequence[currentIndex]
        activeCell = cell
        revealedCells[cell.row][cell.col] = true // Mark cell as revealed
        playBeepSound() // Play beep to indicate it's ready
    }

    // Handles user tapping a cell
    func handleTap(row: Int, col: Int) {
        if row == activeCell?.row && col == activeCell?.col {
            // If the tapped cell is the active one
            tappedCells[row][col] = true
            tapOrder[row][col] = tapCounter // Record tap order
            tapCounter += 1

            activeCell = nil // Deactivate the cell
            currentIndex += 1 // Move to next cell

            if currentIndex == sequence.count {
                // All cells completed
                if checkIfAllTapped() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        gameStarted = false
                        showSummary = true
                        printTapData() // Output results to console
                    }
                }
            } else {
                // Move to the next cell after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showNextCell()
                }
            }
        }
    }

    // Determines the color of each cell
    func getCellColor(row: Int, col: Int) -> Color {
        if tappedCells[row][col] {
            return .black // Already tapped
        } else if activeCell?.row == row && activeCell?.col == col {
            return .red // Currently active cell
        } else if revealedCells[row][col] {
            return .black // Revealed but not active
        }
        return .black // Default
    }

    // Plays a beep sound to notify user that a cell is ready
    func playBeepSound() {
        guard let soundURL = Bundle.main.url(forResource: "542016__rob_marion__gasp_ui_notification_5", withExtension: "wav") else {
            print("Beep sound not found!")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing beep sound: \(error.localizedDescription)")
        }
    }

    // Checks if all revealed cells were tapped
    func checkIfAllTapped() -> Bool {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if revealedCells[row][col] && !tappedCells[row][col] {
                    return false // Found a revealed cell that wasn't tapped
                }
            }
        }
        return true
    }

    // Resets the game state
    func resetGame() {
        tappedCells = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        revealedCells = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        tapOrder = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        activeCell = nil
        currentIndex = 0
        sequence = []
        tapCounter = 1
        showSummary = false
    }

    // Prints the matrix of tap order to console
    func printTapData() {
        print("\n📋 Tap Order Matrix:")

        // Print column headers (1-based)
        var headerRow = "    "
        for col in 1...gridSize {
            headerRow += String(format: "%3d", col)
        }
        print(headerRow)

        // Print each row
        for row in 0..<gridSize {
            var rowString = String(format: "%3d", row + 1) + " "
            for col in 0..<gridSize {
                if let order = tapOrder[row][col] {
                    rowString += String(format: "%3d", order)
                } else {
                    rowString += "  -"
                }
            }
            print(rowString)
        }
    }
}
