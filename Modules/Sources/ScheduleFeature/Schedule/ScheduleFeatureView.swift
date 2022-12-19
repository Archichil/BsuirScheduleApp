import SwiftUI
import BsuirCore
import LoadableFeature
import ComposableArchitecture
import ComposableArchitectureUtils

public struct ScheduleFeatureView<Value: Equatable>: View {
    struct ViewState: Equatable {
        let title: String
        let isFavorite: Bool
        let isPinned: Bool
        let scheduleType: ScheduleDisplayType

        init(state: ScheduleFeature<Value>.State) {
            self.title = state.title
            self.isFavorite = state.isFavorite
            self.isPinned = state.isPinned
            self.scheduleType = state.scheduleType
        }
    }

    public let store: StoreOf<ScheduleFeature<Value>>
    public let schedulePairDetails: ScheduleGridViewPairDetails
    
    public init(store: StoreOf<ScheduleFeature<Value>>, schedulePairDetails: ScheduleGridViewPairDetails) {
        self.store = store
        self.schedulePairDetails = schedulePairDetails
    }

    public var body: some View {
        
        WithViewStore(store, observe: ViewState.init) { viewStore in
            LoadingStore(
                store,
                state: \.$schedule,
                action: { .schedule($0) }
            ) { store in
                LoadedScheduleView(
                    store: store.loaded(),
                    scheduleType: viewStore.scheduleType,
                    schedulePairDetails: schedulePairDetails
                )
                .refreshable { await ViewStore(store.stateless).send(.refresh).finish() }
            } loading: {
                ScheduleGridPlaceholder()
            } error: { store in
                LoadingErrorView(store: store)
            }
            .toolbar {
                ToolbarItem {
                    HStack {
                        ToggleFavoritesButton(
                            isFavorite: viewStore.isFavorite,
                            toggle: { viewStore.send(.toggleFavoritesTapped) }
                        )
                        TogglePinnedButton(
                            isPinned: viewStore.isPinned,
                            toggle: { viewStore.send(.toggleIsPinnedTapped) }
                        )
                        ScheduleDisplayTypePickerMenu(
                            scheduleType: viewStore.binding(
                                get: \.scheduleType,
                                send: { .view(.setScheduleType($0)) }
                            )
                        )
                    }
                }
            }
            .navigationTitle(viewStore.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct LoadedScheduleView: View {
    let store: StoreOf<LoadedScheduleReducer>
    let scheduleType: ScheduleDisplayType
    let schedulePairDetails: ScheduleGridViewPairDetails

    var body: some View {
        switch scheduleType {
        case .compact:
            DayScheduleView(
                store: store.scope(state: \.compact, action: { .day($0) })
            )
        case .continuous:
            ContiniousScheduleView(
                store: store.scope(state: \.continious, action: { .continious($0) }),
                pairDetails: schedulePairDetails
            )
        case .exams:
            ExamsScheduleView(
                store: store.scope(state: \.exams, action: { .exams($0) }),
                pairDetails: schedulePairDetails
            )
        }
    }
}

private struct TogglePinnedButton: View {
    var isPinned: Bool
    var toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
        }
        .accessibility(
            label: isPinned
                ? Text("screen.schedule.favorite.accessibility.remove")
                : Text("screen.schedule.favorite.accessibility.add")
        )
    }
}

private struct ToggleFavoritesButton: View {
    let isFavorite: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
        .accessibility(
            label: isFavorite
                ? Text("screen.schedule.favorite.accessibility.remove")
                : Text("screen.schedule.favorite.accessibility.add")
        )
        .accentColor(.yellow)
    }
}
