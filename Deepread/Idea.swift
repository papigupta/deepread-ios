import Foundation
import SwiftData

/// Immutable concept wrapper with a sequential ID (`i1`, `i2`, …).
@Model
final class Idea {
    var id: String     // e.g. "i1"
    var title: String  // e.g. "Godel's Incompleteness Theorem"
    var ideaDescription: String  // e.g. "Mathematical systems cannot prove their own consistency."
    var bookTitle: String  // e.g. "Godel, Escher, Bach"
    var depthTarget: Int  // 1 = Do, 2 = Question, 3 = Reinvent
    var masteryLevel: Int // 0 = not started, 1 = basic, 2 = intermediate, 3 = mastered
    var lastPracticed: Date?
    var currentLevel: Int? // The exact level user was on when they left
    
    // Relationship back to Book
    @Relationship(deleteRule: .cascade) var book: Book?
    
    // Relationships to UserResponse and Progress
    @Relationship(deleteRule: .cascade) var responses: [UserResponse]
    @Relationship(deleteRule: .cascade) var progress: [Progress]
    
    init(id: String, title: String, description: String, bookTitle: String, depthTarget: Int, masteryLevel: Int = 0, lastPracticed: Date? = nil, currentLevel: Int? = nil) {
        self.id = id
        self.title = title
        self.ideaDescription = description
        self.bookTitle = bookTitle
        self.depthTarget = depthTarget
        self.masteryLevel = masteryLevel
        self.lastPracticed = lastPracticed
        self.currentLevel = currentLevel
        self.responses = []
        self.progress = []
        print("DEBUG: Created Idea with id: \(id), title: \(title), bookTitle: \(bookTitle)")
    }
} 