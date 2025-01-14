import Foundation
import GroupsFeature
import LecturersFeature
import SettingsFeature
import Deeplinking
import Favorites
import ScheduleCore
import PremiumClubFeature
import ComposableArchitecture
import EntityScheduleFeature
import ScheduleFeature

@Reducer
public struct AppFeature {
    @Reducer
    public enum Destination {
        case settings(SettingsFeature)
        case premiumClub(PremiumClubFeature)
    }

    @ObservableState
    public struct State {
        @Presents var destination: Destination.State?

        var selection: CurrentSelection = .groups

        var pinnedTab = PinnedTabFeature.State()
        var groups = GroupsFeature.State()
        var lecturers = LecturersFeature.State()
        var settings = SettingsFeature.State()

        public init() {
            @Dependency(\.favorites) var favorites
            @Dependency(\.pinnedScheduleService) var pinnedScheduleService
            self.handleInitialSelection(favorites: favorites, pinnedScheduleService: pinnedScheduleService)
        }
    }

    public enum Action {
        case destination(PresentationAction<Destination.Action>)

        case task
        case closePremiumClubButtonTapped

        case handleDeeplink(URL)
        case setSelection(CurrentSelection)
        case setPinnedSchedule(ScheduleSource?)
        case showSettingsButtonTapped

        case pinnedTab(PinnedTabFeature.Action)
        case groups(GroupsFeature.Action)
        case lecturers(LecturersFeature.Action)
        case settings(SettingsFeature.Action)
    }

    @Dependency(\.favorites) var favorites
    @Dependency(\.productsService) var productsService
    @Dependency(\.pinnedScheduleService) var pinnedScheduleService

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    for await pinnedSchedule in pinnedScheduleService.schedule().values {
                        // Give time for schedule feature to handle unpin before removing tab view
                        await Task.yield()
                        await send(.setPinnedSchedule(pinnedSchedule))
                    }
                }

            case .closePremiumClubButtonTapped:
                state.destination = nil
                return .none

            case let .setSelection(value):
                state.updateSelection(value)
                return .none

            case .setPinnedSchedule(nil):
                state.pinnedTab.resetPinned()
                return .none

            case let .setPinnedSchedule(pinned?):
                state.pinnedTab.show(pinned: pinned)
                return .none

            case .showSettingsButtonTapped:
                state.destination = .settings(state.settings)
                return .none

            case let .handleDeeplink(url):
                do {
                    let deeplink = try deeplinkRouter.match(url: url)
                    handleDeeplink(state: &state, deeplink: deeplink)
                } catch {
                    assertionFailure("Failed to parse deeplink. \(error.localizedDescription)")
                }
                return .none

            case .pinnedTab(.delegate(let action)):
                switch action {
                case .showPremiumClubPinned:
                    showPremiumClub(state: &state, source: .pin)
                    return .none
                }

            case .groups(.delegate(let action)):
                switch action {
                case .showPremiumClubPinned:
                    showPremiumClub(state: &state, source: .pin)
                    return .none
                }

            case .lecturers(.delegate(let action)):
                switch action {
                case .showPremiumClubPinned:
                    showPremiumClub(state: &state, source: .pin)
                    return .none
                }

            case .settings(.delegate(let action)):
                switch action {
                case let .showPremiumClub(source):
                    showPremiumClub(state: &state, source: source)
                    return .none
                }

            case .groups, .lecturers, .settings, .pinnedTab, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)

        Scope(state: \.pinnedTab, action: \.pinnedTab) {
            PinnedTabFeature()
        }

        Scope(state: \.groups, action: \.groups) {
            GroupsFeature()
        }

        Scope(state: \.lecturers, action: \.lecturers) {
            LecturersFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
    }

    private func showPremiumClub(state: inout State, source: PremiumClubFeature.Source?) {
        state.destination = .premiumClub(PremiumClubFeature.State(
            isModal: true,
            source: source
        ))
    }
}
