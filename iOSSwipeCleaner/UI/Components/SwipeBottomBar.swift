import SwiftUI

struct SwipeBottomBar: View {
    let activeTab: SwipeTab
    let keptCount: Int
    let trashCount: Int
    let onSelect: (SwipeTab) -> Void

    var body: some View {
        HStack {
            item(.swipe, title: "Swipe", icon: "square.stack.fill", badge: 0, badgeColor: Theme.primary)
            item(.kept, title: "Kept", icon: "heart.fill", badge: keptCount, badgeColor: Theme.keep)
            item(.trash, title: "Trash", icon: "trash.fill", badge: trashCount, badgeColor: Theme.delete)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Theme.surface.ignoresSafeArea(edges: .bottom))
    }

    private func item(_ tab: SwipeTab, title: String, icon: String, badge: Int, badgeColor: Color) -> some View {
        let isActive = tab == activeTab
        return Button { onSelect(tab) } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .frame(height: 28)
                    if badge > 0 {
                        Text(badge > 999 ? "999+" : "\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(badgeColor))
                            .offset(x: 12, y: -6)
                    }
                }
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isActive ? Theme.primary : Theme.secondaryText)
        }
        .accessibilityLabel(badge > 0 ? "\(title), \(badge)" : title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
