//
//  CoverFlow.swift
//  AssistanceKit
//
//  Extracted from SoundCheck/CoverFlow.swift for cross-project reuse.
//

#if canImport(SwiftUI)
import SwiftUI

/// A 3D card carousel with gesture-driven scrolling, tap selection,
/// double-tap, and drag-out support.
///
/// Generic over the item type and card view. Items must be `Identifiable`.
/// The focused card is communicated via a two-way `focusedID` binding.
public struct CoverFlow<Item: Identifiable, Card: View>: View {
    public let items: [Item]
    @Binding public var focusedID: Item.ID?
    public let cardSize: CGSize
    public let flowWidth: CGFloat?
    public let tuning: CoverFlowTuning
    public let coordinateSpace: String
    public let focusAnimation: Animation?
    public let onSelect: (Item) -> Void
    public let onDoubleTap: ((Item) -> Void)?
    public let onTapEmptySpace: (() -> Void)?
    public let onDragOutBegan: ((CoverFlowDragOut<Item.ID>) -> Void)?
    public let onDragOutMoved: ((CoverFlowDragOutMove) -> Void)?
    public let onDragOutEnded: (() -> Void)?
    public let draggedOutItemID: Item.ID?
    /// 0 = card still in stack, 1 = card fully removed. Controls gradual gap closing.
    public let dragOutProgress: CGFloat
    public let incomingProgress: CGFloat
    public let card: (Item) -> Card

    // Continuous scroll position for the cover flow (expressed in item indices).
    @State private var scrollPosition: CGFloat = 0
    // Tracks which interaction mode the engine is currently in.
    @State private var engineMode: EngineMode = .idle
    // Scroll position captured at the start of a gesture.
    @State private var scrollStartPosition: CGFloat?
    // Tracks the last tap for double-tap detection.
    @State private var lastTapTime: Date?
    @State private var lastTapItemIndex: Int?
    // Index of the card being dragged out (used for gap animation).
    @State private var dragOutIndex: Int?

    public init(
        items: [Item],
        focusedID: Binding<Item.ID?>,
        cardSize: CGSize,
        flowWidth: CGFloat? = nil,
        tuning: CoverFlowTuning = .default,
        coordinateSpace: String,
        focusAnimation: Animation? = CoverFlowAnimationStyle.focusSpring,
        onSelect: @escaping (Item) -> Void,
        onDoubleTap: ((Item) -> Void)? = nil,
        onTapEmptySpace: (() -> Void)? = nil,
        onDragOutBegan: ((CoverFlowDragOut<Item.ID>) -> Void)? = nil,
        onDragOutMoved: ((CoverFlowDragOutMove) -> Void)? = nil,
        onDragOutEnded: (() -> Void)? = nil,
        draggedOutItemID: Item.ID? = nil,
        dragOutProgress: CGFloat = 0,
        incomingProgress: CGFloat = 0,
        @ViewBuilder card: @escaping (Item) -> Card
    ) {
        self.items = items
        self._focusedID = focusedID
        self.cardSize = cardSize
        self.flowWidth = flowWidth
        self.tuning = tuning
        self.coordinateSpace = coordinateSpace
        self.focusAnimation = focusAnimation
        self.onSelect = onSelect
        self.onDoubleTap = onDoubleTap
        self.onTapEmptySpace = onTapEmptySpace
        self.onDragOutBegan = onDragOutBegan
        self.onDragOutMoved = onDragOutMoved
        self.onDragOutEnded = onDragOutEnded
        self.draggedOutItemID = draggedOutItemID
        self.dragOutProgress = dragOutProgress
        self.incomingProgress = incomingProgress
        self.card = card
    }

    /// Tracks how the engine should interpret user interactions.
    private enum EngineMode: Equatable {
        case idle
        case undecided
        case scrolling
        case draggingCard(Int)
        case snapping(CGFloat)
    }

    /// Calculated layout values for a single card.
    private struct CardLayout {
        let position: CGPoint
        let scale: CGFloat
        let tilt: CGFloat
        let zIndex: Double
    }

    public var body: some View {
        GeometryReader { outer in
            let effectiveFlowWidth = flowWidth ?? outer.size.width
            let flowHeight = cardSize.height * tuning.flowHeightScale
            let currentFocusID = resolvedFocusedID()
            cardStack(outerSize: CGSize(width: effectiveFlowWidth, height: flowHeight), resolvedFocusID: currentFocusID)
                .frame(width: effectiveFlowWidth, height: flowHeight, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
                .gesture(makeDragGesture(outerWidth: effectiveFlowWidth))
        }
        .frame(height: cardSize.height * tuning.flowHeightScale)
        .onAppear {
            syncScrollPositionFromFocusedID(items: items)
            initializeFocusedIDIfNeeded(items: items)
        }
        .onChangeCompat(of: items.map(\.id)) {
            clampScrollPositionToValidRange(items: items)
            syncScrollPositionFromFocusedID(items: items)
            initializeFocusedIDIfNeeded(items: items)
        }
        .onChangeCompat(of: focusedID) {
            syncScrollPositionFromFocusedID(items: items)
        }
        .onChangeCompat(of: scrollPosition) {
            updateSnapCompletion(items: items)
        }
        .onChangeCompat(of: draggedOutItemID) {
            if draggedOutItemID == nil {
                dragOutIndex = nil
            }
        }
    }

    private func makeDragGesture(outerWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpace))
            .onChanged { value in handleDragChanged(value, outerWidth: outerWidth) }
            .onEnded { value in handleDragEnded(value, outerWidth: outerWidth) }
    }

    private func resolvedFocusedID() -> Item.ID? {
        let kernel = CoverFlowKernel(scrollPosition: scrollPosition, itemCount: items.count)
        let idx = kernel.focusedIndex
        return items.indices.contains(idx) ? items[idx].id : nil
    }

    private func cardStack(outerSize: CGSize, resolvedFocusID: Item.ID?) -> some View {
        let indexByID = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($0.element.id, $0.offset) })
        return ZStack {
            ForEach(items, id: \.id) { item in
                let itemIndex = indexByID[item.id] ?? 0
                let isDraggedOut = item.id == draggedOutItemID
                let adjustedIndex = adjustedItemIndex(
                    itemIndex: itemIndex,
                    dragOutIndex: dragOutIndex,
                    dragOutProgress: dragOutProgress,
                    incomingProgress: incomingProgress,
                    itemCount: items.count
                )
                let layout = layoutForCard(
                    itemIndex: adjustedIndex,
                    scrollPosition: scrollPosition,
                    outerSize: outerSize,
                    cardSize: cardSize
                )
                card(item)
                    .frame(width: cardSize.width, height: cardSize.height, alignment: .center)
                    .scaleEffect(layout.scale)
                    .rotation3DEffect(
                        .degrees(Double(layout.tilt)),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: tuning.perspective
                    )
                    .position(x: layout.position.x, y: layout.position.y)
                    .zIndex(layout.zIndex)
                    .opacity(isDraggedOut ? 0 : 1)
                    .animation(focusAnimation, value: resolvedFocusID)
            }
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value, outerWidth: CGFloat) {
        let dx = value.translation.width
        let dy = value.translation.height
        let step = outerWidth * CoverFlowInteractionStyle.snapStepFraction

        if scrollStartPosition == nil {
            scrollStartPosition = scrollPosition
        }

        switch engineMode {
        case .idle, .snapping:
            engineMode = .undecided
        case .undecided:
            let absDx = abs(dx)
            let absDy = abs(dy)
            if absDx >= CoverFlowInteractionStyle.tapDistanceThreshold ||
               absDy >= CoverFlowInteractionStyle.tapDistanceThreshold {
                // Only allow vertical card drag when drag-out callbacks are provided.
                if onDragOutBegan != nil,
                   absDy > absDx * CoverFlowInteractionStyle.verticalDragRatio,
                   let dragIndex = hitTestIndex(at: value.startLocation.x, outerWidth: outerWidth) {
                    engineMode = .draggingCard(dragIndex)
                    dragOutIndex = dragIndex
                    let layout = layoutForCard(
                        itemIndex: CGFloat(dragIndex),
                        scrollPosition: scrollPosition,
                        outerSize: CGSize(width: outerWidth, height: 0),
                        cardSize: cardSize
                    )
                    if items.indices.contains(dragIndex) {
                        let info = CoverFlowDragOut(
                            itemID: items[dragIndex].id,
                            itemIndex: dragIndex,
                            startPosition: CGPoint(x: layout.position.x, y: value.startLocation.y),
                            initialTiltDegrees: layout.tilt
                        )
                        onDragOutBegan?(info)
                    }
                } else {
                    engineMode = .scrolling
                    updateScrollPosition(translationX: dx, step: step)
                }
            }
        case .scrolling:
            updateScrollPosition(translationX: dx, step: step)
        case .draggingCard:
            // Horizontal movement scrolls the CoverFlow only while the card
            // is still near the source (within one card-height vertically).
            if abs(dy) < cardSize.height {
                updateScrollPosition(translationX: dx, step: step)
            }
            let move = CoverFlowDragOutMove(
                currentPosition: value.location,
                translation: CGSize(width: dx, height: dy)
            )
            onDragOutMoved?(move)
        }
    }

    private func hitTestIndex(at tapX: CGFloat, outerWidth: CGFloat) -> Int? {
        CoverFlowKernel.hitTestCardIndex(
            tapX: tapX,
            scrollPosition: scrollPosition,
            itemCount: items.count,
            outerWidth: outerWidth,
            cardWidth: cardSize.width,
            tuning: tuning
        )
    }

    private func handleDragEnded(_ value: DragGesture.Value, outerWidth: CGFloat) {
        switch engineMode {
        case .draggingCard:
            onDragOutEnded?()
            engineMode = .idle
            scrollStartPosition = nil
            return
        case .undecided:
            let isTap = abs(value.translation.width) < CoverFlowInteractionStyle.tapDistanceThreshold
                     && abs(value.translation.height) < CoverFlowInteractionStyle.tapDistanceThreshold
            if isTap {
                handleTapGesture(at: value.startLocation.x, outerWidth: outerWidth)
            } else {
                snapToNearestCard()
            }
        case .scrolling:
            snapToNearestCard()
        default:
            snapToNearestCard()
        }
        scrollStartPosition = nil
    }

    private func handleTapGesture(at tapX: CGFloat, outerWidth: CGFloat) {
        guard let tappedIndex = CoverFlowKernel.hitTestCardIndex(
            tapX: tapX,
            scrollPosition: scrollPosition,
            itemCount: items.count,
            outerWidth: outerWidth,
            cardWidth: cardSize.width,
            tuning: tuning
        ) else {
            onTapEmptySpace?()
            snapToNearestCard()
            return
        }

        let now = Date()
        let isDoubleTap: Bool
        if let lastTime = lastTapTime, lastTapItemIndex == tappedIndex,
           now.timeIntervalSince(lastTime) < CoverFlowInteractionStyle.doubleTapInterval {
            isDoubleTap = true
        } else {
            isDoubleTap = false
        }

        // Animate tapped card to center (no-op when already centered).
        let target = CoverFlowKernel.scrollPosition(for: tappedIndex, itemCount: items.count)
        let alreadyFocused = abs(scrollPosition - target) <= CoverFlowAnimationStyle.positionEpsilon

        if alreadyFocused {
            engineMode = .idle
            if !isDoubleTap, items.indices.contains(tappedIndex) {
                onSelect(items[tappedIndex])
            }
        } else {
            engineMode = .snapping(target)
            withAnimation(CoverFlowAnimationStyle.focusSpring) {
                scrollPosition = target
            }
        }

        if isDoubleTap {
            lastTapTime = nil
            lastTapItemIndex = nil
            if items.indices.contains(tappedIndex) {
                onDoubleTap?(items[tappedIndex])
            }
        } else {
            lastTapTime = now
            lastTapItemIndex = tappedIndex
        }
    }

    private func snapToNearestCard() {
        let kernel = CoverFlowKernel(scrollPosition: scrollPosition, itemCount: items.count)
        let target = CoverFlowKernel.scrollPosition(for: kernel.focusedIndex, itemCount: items.count)
        if abs(scrollPosition - target) <= CoverFlowAnimationStyle.positionEpsilon {
            engineMode = .idle
            updateFocusedIDFromScroll(items: items)
            return
        }
        engineMode = .snapping(target)
        withAnimation(CoverFlowAnimationStyle.focusSpring) {
            scrollPosition = target
        }
    }

    private func updateScrollPosition(translationX: CGFloat, step: CGFloat) {
        guard step > 0 else { return }
        let base = scrollStartPosition ?? scrollPosition
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            scrollPosition = base - (translationX / step)
        }
    }

    private func clampScrollPositionToValidRange(items: [Item]) {
        engineMode = .idle
        guard items.count > 0 else { return }
        let maxPosition = CGFloat(items.count - 1)
        if scrollPosition > maxPosition {
            scrollPosition = maxPosition
        }
    }

    private func syncScrollPositionFromFocusedID(items: [Item]) {
        guard scrollStartPosition == nil else {
            return
        }
        guard engineMode != .scrolling else {
            return
        }
        if case .snapping = engineMode {
            return
        }
        if case .draggingCard = engineMode {
            return
        }
        if engineMode == .undecided {
            return
        }
        guard let focusedID,
              let index = items.firstIndex(where: { $0.id == focusedID }) else {
            return
        }
        let newPosition = CoverFlowKernel.scrollPosition(for: index, itemCount: items.count)
        if abs(scrollPosition - newPosition) > CoverFlowAnimationStyle.positionEpsilon {
            scrollPosition = newPosition
        }
    }

    private func initializeFocusedIDIfNeeded(items: [Item]) {
        guard focusedID == nil, !items.isEmpty else { return }
        updateFocusedIDFromScroll(items: items)
    }

    private func updateFocusedIDFromScroll(items: [Item]) {
        if case .draggingCard = engineMode { return }
        if case .snapping = engineMode { return }
        let kernel = CoverFlowKernel(scrollPosition: scrollPosition, itemCount: items.count)
        let index = kernel.focusedIndex
        let newID = items.indices.contains(index) ? items[index].id : nil
        if focusedID != newID {
            focusedID = newID
        }
    }

    private func updateSnapCompletion(items: [Item]) {
        guard case .snapping(let target) = engineMode else { return }
        guard CoverFlowKernel.isSnapComplete(
            scrollPosition: scrollPosition,
            target: target,
            epsilon: CoverFlowAnimationStyle.positionEpsilon
        ) else { return }
        engineMode = .idle
        updateFocusedIDFromScroll(items: items)
    }

    private func adjustedItemIndex(
        itemIndex: Int,
        dragOutIndex: Int?,
        dragOutProgress: CGFloat,
        incomingProgress: CGFloat,
        itemCount: Int
    ) -> CGFloat {
        var adjusted = CGFloat(itemIndex)

        if let outIdx = dragOutIndex, itemIndex > outIdx {
            adjusted -= dragOutProgress
        }

        if incomingProgress > 0 {
            let focusedIdx: Int
            if let fid = focusedID, let idx = items.firstIndex(where: { $0.id == fid }) {
                focusedIdx = idx
            } else {
                focusedIdx = CoverFlowKernel(scrollPosition: scrollPosition, itemCount: itemCount).focusedIndex
            }
            let effectiveIdx: Int
            if let outIdx = dragOutIndex, itemIndex > outIdx {
                effectiveIdx = itemIndex - 1
            } else {
                effectiveIdx = itemIndex
            }
            if effectiveIdx >= focusedIdx {
                adjusted += incomingProgress
            }
        }

        return adjusted
    }

    private func layoutForCard(
        itemIndex: CGFloat,
        scrollPosition: CGFloat,
        outerSize: CGSize,
        cardSize: CGSize
    ) -> CardLayout {
        let d = itemIndex - scrollPosition
        let normalizedOffset = d / tuning.visibleRange
        let clampedOffset = min(max(normalizedOffset, CoverFlowLayoutStyle.normalizedClampMin), CoverFlowLayoutStyle.normalizedClampMax)
        let absOffset = abs(clampedOffset)
        let baseX = atan(d) * outerSize.width * CoverFlowLayoutStyle.baseStackTightness
        let tilt = -clampedOffset * tuning.maxTiltAngle
        let scale = 1 - (absOffset * tuning.scaleReduction)
        let xShift = clampedOffset * outerSize.width * CoverFlowLayoutStyle.baseSideShiftScale
        let yShift = absOffset * cardSize.height * CoverFlowLayoutStyle.sideDropScale
        let depthIndex = Double(CoverFlowLayoutStyle.depthIndexBase) - Double(abs(d))
        let rawCenterX = outerSize.width / CoverFlowLayoutStyle.centerDivider + baseX + xShift
        let scaledHalfCard = cardSize.width * scale / CoverFlowLayoutStyle.centerDivider
        let centerX = min(max(rawCenterX, scaledHalfCard), outerSize.width - scaledHalfCard)
        let position = CGPoint(
            x: centerX,
            y: outerSize.height / CoverFlowLayoutStyle.centerDivider + yShift
        )

        return CardLayout(position: position, scale: scale, tilt: tilt, zIndex: depthIndex)
    }
}
#endif
