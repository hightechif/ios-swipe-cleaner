import Lottie
import XCTest
@testable import iOSSwipeCleaner

final class AppResourcesTests: XCTestCase {
    func testConfettiAnimationIsBundled() {
        let url = Bundle(for: AppBundleToken.self).url(forResource: "completion_animation", withExtension: "json")
        XCTAssertNotNil(url)
    }

    func testConfettiAnimationDecodesWithLottie() throws {
        let animation = try XCTUnwrap(LottieAnimation.named("completion_animation", bundle: Bundle(for: AppBundleToken.self)))
        XCTAssertGreaterThan(animation.duration, 0)
        XCTAssertGreaterThan(animation.size.width, 0)
    }
}
