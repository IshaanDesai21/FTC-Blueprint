import Foundation

enum ReviewKind: String, CaseIterable, Identifiable {
    case portfolio
    case code
    case cad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .portfolio: return "Portfolio".localizedUI
        case .code: return "Code".localizedUI
        case .cad: return "CAD"
        }
    }

    var accessKey: String {
        switch self {
        case .portfolio: return "4b594ea5-d8dd-4fe1-8302-389b8f60f022"
        case .code: return "3dd53572-82f6-44ed-b36f-7e8cdef9c21a"
        case .cad: return "77095db6-97a3-47d6-8768-b2e706abd2c2"
        }
    }

    var subject: String {
        switch self {
        case .portfolio: return "New Portfolio Review Request"
        case .code: return "New Code Review Request"
        case .cad: return "New CAD Review Request"
        }
    }

    var linkFieldName: String {
        switch self {
        case .portfolio: return "portfolio_link"
        case .code: return "code_link"
        case .cad: return "cad_link"
        }
    }

    var linkPlaceholder: String {
        switch self {
        case .portfolio: return "Link to Portfolio".localizedUI
        case .code: return "Link to GitHub Repository".localizedUI
        case .cad: return "Link to CAD (Onshape, Step, etc.)".localizedUI
        }
    }

    var notesPlaceholder: String {
        switch self {
        case .portfolio: return "Notes (Areas to focus on, awards you're chasing...)".localizedUI
        case .code: return "Notes (Areas to focus on, specific bugs or files...)".localizedUI
        case .cad: return "Notes (Specific subsystems, weight issues...)".localizedUI
        }
    }

    var description: String {
        switch self {
        case .portfolio: return "Share your engineering portfolio and we'll give you detailed feedback to help you stand out for judging.".localizedUI
        case .code: return "Share your code with us. We'll provide detailed feedback to help with your code, errors, and logic.".localizedUI
        case .cad: return "Share your CAD and we'll provide feedback on design, manufacturability, and weight.".localizedUI
        }
    }
}
