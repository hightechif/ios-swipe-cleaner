import Lottie
import SwiftUI

/// Plays a bundled Lottie animation once.
struct LottieView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.isUserInteractionEnabled = false
        let animation = LottieAnimationView(name: name, bundle: Bundle(for: AppBundleToken.self))
        animation.loopMode = .playOnce
        animation.contentMode = .scaleAspectFit
        animation.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animation)
        NSLayoutConstraint.activate([
            animation.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animation.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animation.topAnchor.constraint(equalTo: container.topAnchor),
            animation.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        animation.play()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
