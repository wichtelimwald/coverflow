//
//  ViewCompatibility.swift
//  CoverFlow
//
//  Vendored from shared-ui/Sources/AssistanceKit/Compatibility/ViewCompatibility.swift.
//  CoverFlow.swift calls onChangeCompat but the migration manifest only copies
//  the CoverFlow/ subtree, not Compatibility/ — without this the package
//  fails to build. Kept `internal` (not `public`) on purpose: shared-ui also
//  ships a public `onChangeCompat`, and a consumer that imports both CoverFlow
//  and SharedUI in the same file would hit an "ambiguous use" error if both
//  declared the same public extension.
//

#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Backward-compatible `onChange` modifier.
    ///
    /// Uses the iOS 17+ / macOS 14+ API when available, otherwise falls back
    /// to the iOS 14+ / macOS 11+ variant. The closure receives no parameters
    /// (fire-and-forget style).
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, _ action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.onChange(of: value) { action() }
        } else {
            self.onChange(of: value) { _ in action() }
        }
    }
}

#endif
