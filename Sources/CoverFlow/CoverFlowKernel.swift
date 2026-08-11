//
//  CoverFlowKernel.swift
//  AssistanceKit
//
//  Extracted from SoundCheck/CoverFlowKernel.swift for cross-project reuse.
//

import Foundation

/// Pure-logic kernel for CoverFlow scroll position and hit-testing calculations.
///
/// This type is UI-framework-independent and can be used in unit tests
/// without importing SwiftUI.
public struct CoverFlowKernel: Equatable, Sendable {
    public var scrollPosition: CGFloat
    public let itemCount: Int

    public init(scrollPosition: CGFloat, itemCount: Int) {
        self.scrollPosition = scrollPosition
        self.itemCount = itemCount
    }

    public var focusedIndex: Int {
        let rounded = Int(scrollPosition.rounded())
        return Self.clampedIndex(rounded, itemCount: itemCount)
    }

    public static func clampedIndex(_ index: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return min(max(index, 0), itemCount - 1)
    }

    public static func scrollPosition(for index: Int, itemCount: Int) -> CGFloat {
        CGFloat(clampedIndex(index, itemCount: itemCount))
    }

    public static func isSnapComplete(scrollPosition: CGFloat, target: CGFloat, epsilon: CGFloat) -> Bool {
        abs(scrollPosition - target) <= epsilon
    }

    /// Computes the insertion index for a card being dropped into a list.
    /// Uses the focused item's index as the insertion point (where the visual
    /// gap opens).  Falls back to `0` (front of list) when `focusedID` is nil
    /// or not found — this matches the default scroll position 0.
    public static func insertionIndex<ID: Equatable>(focusedID: ID?, in list: [ID]) -> Int {
        if let fid = focusedID, let idx = list.firstIndex(of: fid) {
            return idx
        }
        return 0
    }

    /// Returns the item index of the frontmost card whose visual bounds contain `tapX`,
    /// or `nil` when no card is hit. Cards are checked front-to-back (highest z-index first).
    public static func hitTestCardIndex(
        tapX: CGFloat,
        scrollPosition: CGFloat,
        itemCount: Int,
        outerWidth: CGFloat,
        cardWidth: CGFloat,
        tuning: CoverFlowTuning
    ) -> Int? {
        guard itemCount > 0 else { return nil }

        var best: (index: Int, zIndex: Double)?

        for i in 0..<itemCount {
            let d = CGFloat(i) - scrollPosition
            let normalizedOffset = d / tuning.visibleRange
            let clampedOffset = min(max(normalizedOffset, -1), 1)
            let absOffset = abs(clampedOffset)

            let baseX = atan(d) * outerWidth * CoverFlowLayoutStyle.baseStackTightness
            let xShift = clampedOffset * outerWidth * CoverFlowLayoutStyle.baseSideShiftScale
            let scale = 1 - (absOffset * tuning.scaleReduction)
            let scaledHalfCard = cardWidth * scale / 2
            let rawCenterX = outerWidth / 2 + baseX + xShift
            let centerX = min(max(rawCenterX, scaledHalfCard), outerWidth - scaledHalfCard)

            let tiltRad = abs(clampedOffset * tuning.maxTiltAngle) * .pi / 180
            let visibleHalfWidth = cardWidth * scale * cos(tiltRad) / 2

            guard tapX >= centerX - visibleHalfWidth && tapX <= centerX + visibleHalfWidth else {
                continue
            }

            let zIndex = 100.0 - abs(Double(d))
            if let current = best {
                if zIndex > current.zIndex {
                    best = (i, zIndex)
                }
            } else {
                best = (i, zIndex)
            }
        }

        return best?.index
    }
}
