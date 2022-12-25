import SwiftUI
import BsuirUI
import BsuirApi
import LoadableFeature
import EntityScheduleFeature
import ComposableArchitecture

public struct GroupsFeatureView: View {
    public let store: StoreOf<GroupsFeature>
    
    public init(store: StoreOf<GroupsFeature>) {
        self.store = store
    }

    struct ViewState: Equatable {
        let isOnTop: Bool
        let groupSchedule: GroupScheduleFeature.State?
        let hasPinned: Bool
        let numberOfFavorites: Int

        init(_ state: GroupsFeature.State) {
            self.isOnTop = state.isOnTop
            self.groupSchedule = state.groupSchedule
            self.hasPinned = state.pinned != nil
            self.numberOfFavorites = state.favorites?.groupRows.count ?? 0
        }
    }
    
    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            LoadingGroupsView(
                store: store,
                hasPinned: viewStore.hasPinned,
                numberOfFavorites: viewStore.numberOfFavorites,
                isOnTop: viewStore.binding(get: \.isOnTop, send: { .view(.setIsOnTop($0)) })
            )
            .navigationTitle("screen.groups.navigation.title")
            .task { await viewStore.send(.task).finish() }
            .navigation(
                item: viewStore.binding(get: \.groupSchedule, send: { .view(.setGroupSchedule($0)) })
            ) { _ in
                IfLetStore(
                    store
                        .scope(state: \.groupSchedule, reducerAction: { .groupSchedule($0) })
                        .returningLastNonNilState()
                ) { store in
                    GroupScheduleView(store: store)
                }
            }
        }
    }
}

private struct LoadingGroupsView: View {
    let store: StoreOf<GroupsFeature>
    let hasPinned: Bool
    let numberOfFavorites: Int
    @Binding var isOnTop: Bool

    var body: some View {
        LoadingStore(
            store,
            state: \.$sections,
            loading: \.$loadedGroups,
            action: GroupsFeature.Action.groupSection
        ) { store in
            ScrollableToTopList(isOnTop: $isOnTop) {
                IfLetStore(self.store.scope(state: \.pinned, reducerAction: { .pinned($0) })) { store in
                    GroupSectionView(store: store)
                }

                IfLetStore(self.store.scope(state: \.favorites, reducerAction: { .favorites($0) })) { store in
                    GroupSectionView(store: store)
                }

                ForEachStore(store.loaded()) { store in
                    GroupSectionView(store: store)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await ViewStore(store.stateless).send(.refresh).finish() }
            .groupSearchable(store: self.store.scope(state: \.search, reducerAction: { .search($0) }))
        } loading: {
            GroupsPlaceholderView(hasPinned: hasPinned, numberOfFavorites: numberOfFavorites)
        } error: { store in
            LoadingErrorView(store: store)
        }
    }
}

