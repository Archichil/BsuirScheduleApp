import Foundation
import ComposableArchitecture

public struct PremiumClubFeature: Reducer {
    public enum Source {
        case pin
        case appIcon
    }

    enum Section: Hashable, Identifiable {
        var id: Self { self }

        case pinnedSchedule
        case widgets
        case appIcons
        case tips
        case clubExpiration
    }

    public struct State: Equatable {
        public var source: Source?
        public var hasPremium: Bool

        var sections: [Section] {
            let sections: [Section]
            switch source {
            case nil, .pin:
                sections = [.pinnedSchedule, .widgets, .appIcons, .tips]
            case .appIcon:
                sections = [.appIcons, .pinnedSchedule, .widgets, .tips]
            }

            return hasPremium ? [.clubExpiration] + sections : sections
        }

        var tips = TipsSection.State()
        var clubExpiration: ClubExpirationSection.State
        var subsctiptionFooter = SubscriptionFooter.State()

        public init(
            source: Source? = nil,
            hasPremium: Bool? = nil
        ) {
            self.source = source
            @Dependency(\.premiumService) var premiumService
            self.hasPremium = hasPremium ?? premiumService.isCurrentlyPremium
            self.clubExpiration = .init(expiration: premiumService.premiumExpirationDate)
        }
    }

    public enum Action: Equatable {
        case task
        case restoreButtonTapped
        case _setIsPremium(Bool)
        case tips(TipsSection.Action)
        case clubExpiration(ClubExpirationSection.Action)
        case subsctiptionFooter(SubscriptionFooter.Action)
    }

    @Dependency(\.productsService) var productsService
    @Dependency(\.premiumService) var premiumService

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return listenToPremiumUpdates()
                
            case .restoreButtonTapped:
                return .fireAndForget { await productsService.restore() }

            case let ._setIsPremium(value):
                state.hasPremium = value
                state.clubExpiration.expiration = premiumService.premiumExpirationDate
                return .none

            default:
                return .none
            }
        }

        Scope(state: \.tips, action: /Action.tips) {
            TipsSection()
        }

        Scope(state: \.clubExpiration, action: /Action.clubExpiration) {
            ClubExpirationSection()
        }

        Scope(state: \.subsctiptionFooter, action: /Action.subsctiptionFooter) {
            SubscriptionFooter()
        }
    }

    private func listenToPremiumUpdates() -> Effect<Action> {
        return .run { send in
            for await value in premiumService.isPremium.removeDuplicates().values {
                await send(._setIsPremium(value))
            }
        }
    }
}
