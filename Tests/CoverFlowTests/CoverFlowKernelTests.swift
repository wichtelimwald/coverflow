//
//  CoverFlowKernelTests.swift
//  AssistanceKitTests
//
//  Migrated from SoundCheckTests/CoverFlowKernelTests.swift.
//

import XCTest
@testable import CoverFlow

final class CoverFlowKernelTests: XCTestCase {
    func testFocusedIndexDerivation() {
        XCTAssertEqual(CoverFlowKernel(scrollPosition: 1.49, itemCount: 5).focusedIndex, 1)
        XCTAssertEqual(CoverFlowKernel(scrollPosition: 1.5, itemCount: 5).focusedIndex, 2)
        XCTAssertEqual(CoverFlowKernel(scrollPosition: -3, itemCount: 5).focusedIndex, 0)
        XCTAssertEqual(CoverFlowKernel(scrollPosition: 9.2, itemCount: 5).focusedIndex, 4)
    }

    func testSnapCompletionWithinEpsilon() {
        XCTAssertTrue(CoverFlowKernel.isSnapComplete(scrollPosition: 2.001, target: 2.0, epsilon: 0.01))
    }

    func testSnapCompletionOutsideEpsilon() {
        XCTAssertFalse(CoverFlowKernel.isSnapComplete(scrollPosition: 2.02, target: 2.0, epsilon: 0.01))
    }

    // MARK: - Hit-Test

    private var defaultTuning: CoverFlowTuning { .default }

    func testHitTestCenterCardReturnsFocusedIndex() {
        let result = CoverFlowKernel.hitTestCardIndex(
            tapX: 200,
            scrollPosition: 2,
            itemCount: 5,
            outerWidth: 400,
            cardWidth: 120,
            tuning: defaultTuning
        )
        XCTAssertEqual(result, 2)
    }

    func testHitTestReturnsNilForEmptyItems() {
        let result = CoverFlowKernel.hitTestCardIndex(
            tapX: 200,
            scrollPosition: 0,
            itemCount: 0,
            outerWidth: 400,
            cardWidth: 120,
            tuning: defaultTuning
        )
        XCTAssertNil(result)
    }

    func testHitTestReturnsNilForTapOutsideAllCards() {
        let result = CoverFlowKernel.hitTestCardIndex(
            tapX: 399,
            scrollPosition: 0,
            itemCount: 2,
            outerWidth: 400,
            cardWidth: 60,
            tuning: defaultTuning
        )
        XCTAssertNil(result)
    }

    func testHitTestFrontCardWinsInOverlap() {
        let center: CGFloat = 200
        let result = CoverFlowKernel.hitTestCardIndex(
            tapX: center - 20,
            scrollPosition: 1,
            itemCount: 5,
            outerWidth: 400,
            cardWidth: 120,
            tuning: defaultTuning
        )
        XCTAssertEqual(result, 1, "Center card should win in overlap region")
    }

    func testHitTestSideCardIsReachable() {
        let result = CoverFlowKernel.hitTestCardIndex(
            tapX: 270,
            scrollPosition: 2,
            itemCount: 5,
            outerWidth: 400,
            cardWidth: 120,
            tuning: defaultTuning
        )
        XCTAssertEqual(result, 3, "Should be able to tap a side card")
    }

    // MARK: - Clamp & Scroll Position

    func testClampedIndexClampsToLastWhenBeyondCount() {
        XCTAssertEqual(CoverFlowKernel.clampedIndex(4, itemCount: 4), 3)
    }

    func testClampedIndexClampsToZeroWhenNegative() {
        XCTAssertEqual(CoverFlowKernel.clampedIndex(-1, itemCount: 3), 0)
    }

    func testClampedIndexReturnsZeroForEmptyList() {
        XCTAssertEqual(CoverFlowKernel.clampedIndex(2, itemCount: 0), 0)
    }

    func testScrollPositionClampsToValidRange() {
        let pos = CoverFlowKernel.scrollPosition(for: 10, itemCount: 5)
        XCTAssertEqual(pos, 4)
    }

    func testFocusedIndexAfterItemRemoval() {
        let kernel = CoverFlowKernel(scrollPosition: 4, itemCount: 4)
        XCTAssertEqual(kernel.focusedIndex, 3)
    }

    // MARK: - Insertion Index

    func testInsertionIndexAtFocusedPosition() {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        let list = [a, b, c, d]
        XCTAssertEqual(CoverFlowKernel.insertionIndex(focusedID: b, in: list), 1)
    }

    func testInsertionIndexAtFront() {
        let a = UUID(), b = UUID(), c = UUID()
        let list = [a, b, c]
        XCTAssertEqual(CoverFlowKernel.insertionIndex(focusedID: a, in: list), 0)
    }

    func testInsertionIndexFallsBackToFrontWhenNil() {
        let a = UUID(), b = UUID()
        let list = [a, b]
        XCTAssertEqual(CoverFlowKernel.insertionIndex(focusedID: nil as UUID?, in: list), 0)
    }

    func testInsertionIndexFallsBackToFrontWhenNotFound() {
        let a = UUID(), b = UUID(), missing = UUID()
        let list = [a, b]
        XCTAssertEqual(CoverFlowKernel.insertionIndex(focusedID: missing, in: list), 0)
    }

    func testInsertionAfterFirstCardRemoved() {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID(), e = UUID()

        var active = [a, b, c, d]
        var focusedID: UUID? = a

        active.removeAll { $0 == a }
        focusedID = b
        XCTAssertEqual(active, [b, c, d])
        XCTAssertEqual(focusedID, b)

        let idx = CoverFlowKernel.insertionIndex(focusedID: focusedID, in: active)
        XCTAssertEqual(idx, 0, "Card should be inserted at the front, where the focused card B is")

        active.insert(e, at: idx)
        XCTAssertEqual(active, [e, b, c, d], "E should be at the front")
    }

    func testGapPositionMatchesInsertionWhenScrollDrifts() {
        let a = UUID(), b = UUID(), c = UUID()
        let list = [a, b, c]
        let focusedID: UUID? = a

        let insertIdx = CoverFlowKernel.insertionIndex(focusedID: focusedID, in: list)
        XCTAssertEqual(insertIdx, 0)

        let scrollDerivedIdx = CoverFlowKernel(scrollPosition: 2.0, itemCount: 3).focusedIndex
        XCTAssertEqual(scrollDerivedIdx, 2, "Scroll-derived index would be 2 (wrong)")
        XCTAssertNotEqual(scrollDerivedIdx, insertIdx, "Demonstrates the bug: scroll and insertion disagree")

        let focusedIdx = list.firstIndex(of: focusedID!) ?? scrollDerivedIdx
        XCTAssertEqual(focusedIdx, 0, "focusedID-based gap position matches insertion")
        XCTAssertEqual(focusedIdx, insertIdx, "Gap and insertion now agree")
    }

    func testSnapDoesNotOverwriteParentFocusID() {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        let oldItems = [a, b, c, d]

        let snapScrollPosition: CGFloat = 2.0
        let snapFocusedIndex = CoverFlowKernel(scrollPosition: snapScrollPosition, itemCount: oldItems.count).focusedIndex
        XCTAssertEqual(snapFocusedIndex, 2, "Snap targets index 2 in old items")

        let parentFocusID = b
        let newItems = [b, c, d]

        let staleFocusedIndex = CoverFlowKernel(scrollPosition: snapScrollPosition, itemCount: newItems.count).focusedIndex
        XCTAssertEqual(staleFocusedIndex, 2, "Stale scroll position points to index 2")
        XCTAssertEqual(newItems[staleFocusedIndex], d, "Stale derivation gives D, not B")
        XCTAssertNotEqual(newItems[staleFocusedIndex], parentFocusID,
            "Demonstrates the bug: stale scroll-derived focusedID differs from parent's value")

        let insertIdx = CoverFlowKernel.insertionIndex(focusedID: parentFocusID, in: newItems)
        XCTAssertEqual(insertIdx, 0, "With fix, insertion targets index 0 (where B is) — the front")
    }

    func testFullTwoTransferScenario() {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID(), e = UUID()

        var active: [UUID] = [a, b, c, d]
        var focusedPlayerID: UUID? = a

        active.removeAll { $0 == a }
        if focusedPlayerID == a {
            focusedPlayerID = b
        }

        XCTAssertEqual(active, [b, c, d])
        XCTAssertEqual(focusedPlayerID, b)

        let staleScroll: CGFloat = 2.0
        let staleDerivedIndex = CoverFlowKernel(scrollPosition: staleScroll, itemCount: active.count).focusedIndex
        let staleDerivedFocusID = active[staleDerivedIndex]
        XCTAssertEqual(staleDerivedFocusID, d, "Bug: stale scroll overwrites focusedPlayerID to D")

        let buggyInsertIdx = CoverFlowKernel.insertionIndex(focusedID: d, in: active)
        XCTAssertEqual(buggyInsertIdx, 2, "Bug: insertion targets index 2 (near end)")

        let correctInsertIdx = CoverFlowKernel.insertionIndex(focusedID: focusedPlayerID, in: active)
        XCTAssertEqual(correctInsertIdx, 0, "Fix: insertion targets index 0 (front, where B is)")

        let clampedIdx = min(correctInsertIdx, active.count)
        active.insert(e, at: clampedIdx)
        focusedPlayerID = e

        XCTAssertEqual(active, [e, b, c, d], "E should be at the front")
        XCTAssertEqual(focusedPlayerID, e)
    }

    func testStaleItemsSnapOverwriteFromLog() {
        let coco = UUID(), teddy = UUID(), scarlett = UUID(), tanja = UUID(), test = UUID()

        let staleAvailable = [coco, teddy, scarlett, tanja, test]

        let focusedAvailablePlayerID: UUID? = tanja

        let currentAvailable = [teddy, scarlett, tanja, test]

        let staleIdx = CoverFlowKernel(scrollPosition: 0, itemCount: staleAvailable.count).focusedIndex
        let staleFocusID = staleAvailable[staleIdx]
        XCTAssertEqual(staleFocusID, coco, "Stale snap overwrites to Coco")

        let buggyInsertIdx = CoverFlowKernel.insertionIndex(focusedID: coco, in: currentAvailable)
        XCTAssertEqual(buggyInsertIdx, 0, "With fallback=0, even stale Coco inserts at front (safety net)")

        let correctInsertIdx = CoverFlowKernel.insertionIndex(focusedID: focusedAvailablePlayerID, in: currentAvailable)
        XCTAssertEqual(correctInsertIdx, 2, "Tanja is at index 2 in available")

        XCTAssertTrue(currentAvailable.contains(focusedAvailablePlayerID!))
    }

    // MARK: - Stuck Snap Mode

    func testSnapToNearestCardAlreadyAtTarget() {
        let kernel = CoverFlowKernel(scrollPosition: 2.0, itemCount: 5)
        XCTAssertEqual(kernel.focusedIndex, 2)

        let target = CoverFlowKernel.scrollPosition(for: kernel.focusedIndex, itemCount: 5)
        XCTAssertEqual(target, 2.0, "Target is the same as scrollPosition")

        let alreadyAtTarget = abs(2.0 - target) <= 0.001
        XCTAssertTrue(alreadyAtTarget, "scrollPosition is already at target — snap must complete immediately")
    }
}
