//
//  CoverFlowTypes.swift
//  AssistanceKit
//
//  Extracted from SoundCheck/CoverFlow.swift for cross-project reuse.
//

import Foundation

/// Tuning parameters that control CoverFlow visual behaviour.
public struct CoverFlowTuning: Equatable, Sendable {
    public let scaleReduction: CGFloat
    public let maxTiltAngle: CGFloat
    public let perspective: CGFloat
    public let visibleRange: CGFloat
    public let flowHeightScale: CGFloat

    public init(
        scaleReduction: CGFloat,
        maxTiltAngle: CGFloat,
        perspective: CGFloat,
        visibleRange: CGFloat,
        flowHeightScale: CGFloat
    ) {
        self.scaleReduction = scaleReduction
        self.maxTiltAngle = maxTiltAngle
        self.perspective = perspective
        self.visibleRange = visibleRange
        self.flowHeightScale = flowHeightScale
    }

    public static let `default` = CoverFlowTuning(
        scaleReduction: 0.24,
        maxTiltAngle: 62,
        perspective: 0.72,
        visibleRange: 3.0,
        flowHeightScale: 1.3
    )
}

/// Internal layout constants for CoverFlow card positioning.
public enum CoverFlowLayoutStyle {
    public static let depthIndexBase: CGFloat = 100
    public static let normalizedClampMin: CGFloat = -1
    public static let normalizedClampMax: CGFloat = 1
    public static let centerDivider: CGFloat = 2.0
    /// Multiplier for atan-compressed horizontal spread (flowWidth-proportional).
    public static let baseStackTightness: CGFloat = 0.18
    /// Multiplier for linear side shift (flowWidth-proportional).
    public static let baseSideShiftScale: CGFloat = 0.03
    /// Vertical drop for side cards as fraction of card height.
    public static let sideDropScale: CGFloat = 0.04
}

/// Epsilon for snap completion detection.
public enum CoverFlowConstants {
    public static let positionEpsilon: CGFloat = 0.001
}

// MARK: - SwiftUI-Dependent Types

#if canImport(SwiftUI)
import SwiftUI

/// Information about a card being dragged out of a CoverFlow.
public struct CoverFlowDragOut<ItemID: Equatable>: Equatable {
    public let itemID: ItemID
    public let itemIndex: Int
    public let startPosition: CGPoint
    public let initialTiltDegrees: CGFloat

    public init(itemID: ItemID, itemIndex: Int, startPosition: CGPoint, initialTiltDegrees: CGFloat) {
        self.itemID = itemID
        self.itemIndex = itemIndex
        self.startPosition = startPosition
        self.initialTiltDegrees = initialTiltDegrees
    }
}

/// Current position update during a card drag-out gesture.
public struct CoverFlowDragOutMove: Equatable {
    public let currentPosition: CGPoint
    public let translation: CGSize

    public init(currentPosition: CGPoint, translation: CGSize) {
        self.currentPosition = currentPosition
        self.translation = translation
    }
}

/// Interaction thresholds for CoverFlow gesture handling.
public enum CoverFlowInteractionStyle {
    public static let tapDistanceThreshold: CGFloat = 6
    public static let doubleTapInterval: TimeInterval = 0.4
    public static let verticalDragRatio: CGFloat = 1.2
    /// Snap step as fraction of flow width.
    public static let snapStepFraction: CGFloat = 0.12
}

/// Animation presets for CoverFlow transitions.
public enum CoverFlowAnimationStyle {
    /// Snappy spring animation for focus transitions.
    public static let focusSpring = Animation.spring(response: 0.28, dampingFraction: 0.9, blendDuration: 0.1)
    /// Epsilon for snap completion detection.
    public static let positionEpsilon: CGFloat = CoverFlowConstants.positionEpsilon
}

#endif
