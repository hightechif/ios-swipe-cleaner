import SwiftUI

/// Inline state shown instead of the deck when it is empty or exhausted.
struct SessionFinishedView: View {
    enum Mode: Equatable {
        case empty
        case finished(totalReviewed: Int, kept: Int)
    }

    let mode: Mode
    let deleteQueueSize: Int
    let onEmptyTrash: () -> Void
    let onSeeKept: () -> Void

    var body: some View {
        ZStack {
            if case .finished = mode {
                LottieView(name: "completion_animation")
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 16) {
                switch mode {
                case .empty:
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.primary)
                        .accessibilityHidden(true)
                    Text("Nothing to Review")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("You've reviewed every photo here, or there are no photos to show.")
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                case .finished(let total, let kept):
                    Text("Congratulations! 🎉")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("You've completed reviewing your gallery!")
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                    summary(total: total, kept: kept)
                }
                actions
            }
            .padding(24)
        }
    }

    private func summary(total: Int, kept: Int) -> some View {
        VStack(spacing: 10) {
            Text("Session Summary").font(.headline).foregroundColor(.white)
            row("Total Photos Reviewed", total)
            row("Photos Kept", kept)
            row("Photos Marked for Deletion", deleteQueueSize)
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title).foregroundColor(Theme.secondaryText)
            Spacer()
            Text("\(value)").foregroundColor(.white).font(.body.bold())
        }
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if deleteQueueSize > 0 {
                Button(action: onEmptyTrash) {
                    Text(Formatting.deleteButtonTitle(deleteQueueSize))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(.white)
                        .background(Theme.delete)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            Button(action: onSeeKept) {
                Text("See Kept Photos")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}
