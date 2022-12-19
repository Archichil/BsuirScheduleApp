import SwiftUI
import BsuirCore
import AboutFeature
import GroupsFeature
import LecturersFeature
import EntityScheduleFeature
import ComposableArchitecture
import ComposableArchitectureUtils

struct CompactRootView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: \.selection) { viewStore in
            TabView(selection: viewStore.binding(get: { $0 }, send: AppFeature.Action.setSelection)) {
                IfLetStore(
                    store.scope(
                        state: \.pinned,
                        action: { .pinned($0) }
                    )
                ) { store in
                    WithViewStore(store, observe: \.title) { viewStore in
                        NavigationView {
                            PinnedScheduleView(
                                store: store.scope(state: \.schedule)
                            )
                        }
                        .tab(.pinned(viewStore.state))
                    }
                }

                NavigationView {
                    GroupsView(
                        store: store.scope(
                            state: \.groups,
                            action: AppFeature.Action.groups
                        )
                    )
                }
                .tab(.groups)

                NavigationView {
                    LecturersView(
                        store: store.scope(
                            state: \.lecturers,
                            action: AppFeature.Action.lecturers
                        )
                    )
                }
                .tab(.lecturers)

                NavigationView {
                    AboutView(
                        store: store.scope(
                            state: \.about,
                            action: AppFeature.Action.about
                        )
                    )
                }
                .tab(.about)
            }
        }
    }
}

extension View {
    func tab(_ selection: CurrentSelection) -> some View {
        self
            .tabItem { selection.label }
            .tag(selection)
    }
}
