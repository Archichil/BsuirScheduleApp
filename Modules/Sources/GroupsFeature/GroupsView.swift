import SwiftUI
import BsuirUI
import BsuirApi
import LoadableFeature
import ScheduleFeature
import ComposableArchitecture

public struct GroupsView: View {
    public let store: StoreOf<GroupsFeature>
    
    public init(store: StoreOf<GroupsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            LoadingGroupsView(
                viewStore: viewStore,
                store: store
            )
            .navigationTitle("screen.groups.navigation.title")
            .task { await viewStore.send(.task).finish() }
            .task(id: viewStore.searchQuery) {
                do {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    await viewStore.send(.filterGroups, animation: .default).finish()
                } catch {}
            }
            .navigation(item: viewStore.binding(\.$selectedGroup)) { _ in
                IfLetStore(
                    store.scope(state: \.selectedGroup, action: { .reducer(.groupSchedule($0)) })
                ) { store in
                    ScheduleFeatureView(store: store)
                }
            }
        }
    }
}

extension GroupScheduleFeature.State: Identifiable {
    public var id: String { value }
}

private struct LoadingGroupsView: View {
    let viewStore: ViewStoreOf<GroupsFeature>
    let store: StoreOf<GroupsFeature>
    
    var body: some View {
        LoadingStore(
            store,
            state: \.$sections,
            loading: \.$loadedGroups
        ) { store in
            WithViewStore(store) { sectionsViewStore in
                GroupsContentView(
                    searchQuery: viewStore.binding(\.$searchQuery),
                    favorites: viewStore.favorites,
                    sections: sectionsViewStore.state,
                    select: { viewStore.send(.groupTapped($0)) },
                    refresh: { await sectionsViewStore.send(.refresh).finish() }
                )
            }
        } loading: {
            LoadingStateView()
        } error: { store in
            WithViewStore(store) { viewStore in
                ErrorStateView(retry: { viewStore.send(.reload) })
            }
        }
    }
}
