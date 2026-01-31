import SwiftUI

// MARK: - Design System Tokens

/// Central design tokens for consistent UI across the app
enum DS {
    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Semantic Colors

    enum Colors {
        // Backgrounds
        static let surfacePrimary = Color(nsColor: .windowBackgroundColor)
        static let surfaceSecondary = Color(nsColor: .controlBackgroundColor)
        static let surfaceTertiary = Color(nsColor: .underPageBackgroundColor)
        static let surfaceElevated = Color(nsColor: .windowBackgroundColor)

        // Kanban column backgrounds
        static let columnBackground = Color(nsColor: .controlBackgroundColor).opacity(0.5)
        static let columnBackgroundHover = Color(nsColor: .controlBackgroundColor).opacity(0.7)

        // Card backgrounds
        static let cardBackground = Color(nsColor: .controlBackgroundColor)
        static let cardBackgroundHover = Color(nsColor: .selectedContentBackgroundColor).opacity(0.1)
        static let cardBackgroundDragging = Color(nsColor: .selectedContentBackgroundColor).opacity(0.15)

        // Text
        static let textPrimary = Color(nsColor: .labelColor)
        static let textSecondary = Color(nsColor: .secondaryLabelColor)
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)
        static let textQuaternary = Color(nsColor: .quaternaryLabelColor)

        // Borders
        static let border = Color(nsColor: .separatorColor)
        static let borderSubtle = Color(nsColor: .separatorColor).opacity(0.5)

        // Status colors
        static let statusTodo = Color.gray
        static let statusInProgress = Color.blue
        static let statusReview = Color.orange
        static let statusDone = Color.green

        // Accent colors
        static let accent = Color.accentColor
        static let accentSubtle = Color.accentColor.opacity(0.15)

        // Interactive states
        static let dropTargetActive = Color.accentColor.opacity(0.2)
        static let dropTargetBorder = Color.accentColor

        // Tree sidebar
        static let sidebarSelected = Color(nsColor: .selectedContentBackgroundColor)
        static let sidebarHover = Color(nsColor: .selectedContentBackgroundColor).opacity(0.5)
    }

    // MARK: - Typography

    enum Typography {
        static let cardTitle = Font.system(size: 13, weight: .medium)
        static let cardSubtitle = Font.system(size: 11)
        static let columnHeader = Font.system(size: 12, weight: .semibold)
        static let columnCount = Font.system(size: 11, weight: .medium)
        static let treeItem = Font.system(size: 13)
        static let treeItemSecondary = Font.system(size: 11)
        static let sectionHeader = Font.system(size: 11, weight: .semibold)
        static let badge = Font.system(size: 10, weight: .medium)
    }

    // MARK: - Sizes

    enum Sizes {
        // Sidebar
        static let sidebarMinWidth: CGFloat = 220
        static let sidebarMaxWidth: CGFloat = 350
        static let sidebarIdealWidth: CGFloat = 260

        // Kanban
        static let columnMinWidth: CGFloat = 280
        static let columnMaxWidth: CGFloat = 360
        static let columnIdealWidth: CGFloat = 300
        static let cardMinHeight: CGFloat = 60

        // Tree
        static let treeRowHeight: CGFloat = 32
        static let treeIconSize: CGFloat = 16
        static let treeIndent: CGFloat = 16

        // Interactive
        static let buttonMinTapArea: CGFloat = 28
    }

    // MARK: - Animation

    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let dragSpring = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
    }

    // MARK: - Shadows

    enum Shadow {
        static let card = SwiftUI.Color.black.opacity(0.08)
        static let cardRadius: CGFloat = 4

        static let elevated = SwiftUI.Color.black.opacity(0.15)
        static let elevatedRadius: CGFloat = 8

        static let dragging = SwiftUI.Color.black.opacity(0.2)
        static let draggingRadius: CGFloat = 12
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(isHovered: Bool = false, isDragging: Bool = false) -> some View {
        self
            .background(
                isDragging ? DS.Colors.cardBackgroundDragging :
                isHovered ? DS.Colors.cardBackgroundHover :
                DS.Colors.cardBackground
            )
            .cornerRadius(DS.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Colors.borderSubtle, lineWidth: 1)
            )
            .shadow(
                color: isDragging ? DS.Shadow.dragging : DS.Shadow.card,
                radius: isDragging ? DS.Shadow.draggingRadius : DS.Shadow.cardRadius
            )
    }

    func columnStyle() -> some View {
        self
            .background(DS.Colors.columnBackground)
            .cornerRadius(DS.Radius.lg)
    }

    func dropTargetStyle(isTargeted: Bool) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(
                        isTargeted ? DS.Colors.dropTargetBorder : Color.clear,
                        lineWidth: 2
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .fill(isTargeted ? DS.Colors.dropTargetActive : Color.clear)
            )
    }
}
