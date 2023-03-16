import SwiftUI
import BsuirUI
import EntityScheduleFeature
import PremiumClubFeature
import ComposableArchitecture

struct PinnedTabView: View {
    let store: StoreOf<PinnedTabFeature>

    var body: some View {
        NavigationStack {
            PinnedTabContentView(store: store)
        }
        .tabItem {
            PinnedTabItem(store: store)
        }
    }
}

private struct PinnedTabContentView: View {
    let store: StoreOf<PinnedTabFeature>

    var body: some View {
        WithViewStore(store, observe: \.isPremiumLocked) { viewStore in
            if viewStore.state {
                PinnedScheduleLockedView {
                    viewStore.send(.learnAboutPremiumClubTapped)
                }
            } else {
                IfLetStore(
                    store.scope(
                        state: \.schedule,
                        reducerAction: PinnedTabFeature.Action.ReducerAction.schedule
                    )
                ) { store in
                    PinnedScheduleView(store: store)
                } else: {
                    PinnedScheduleEmptyView()
                    // Reset navigation title left from schedule screen
                        .navigationTitle("")
                }
            }
        }
    }
}

private struct PinnedTabItem: View {
    let store: StoreOf<PinnedTabFeature>

    var body: some View {
        WithViewStore(
            store,
            observe: { $0.isPremiumLocked ? nil : $0.schedule?.title }
        ) { viewStore in
            if let title = viewStore.state {
                PinnedLabel(title: title)
            } else {
                EmptyPinnedLabel()
            }
        }
    }
}