import Foundation
import BsuirCore
import BsuirApi
import ComposableArchitecture
import ComposableArchitectureUtils
import Dependencies

public struct ContiniousScheduleFeature: ReducerProtocol {
    public struct State: Equatable {
        var days: [ScheduleDayViewModel] = []
        @BindableState var isOnTop: Bool?
        fileprivate var schedule: DaySchedule
        fileprivate var offset: Date?
        fileprivate let weekSchedule: WeekSchedule
        fileprivate var mostRelevant: Date?
        
        init(schedule: DaySchedule) {
            self.schedule = schedule
            self.weekSchedule = WeekSchedule(schedule: schedule)
        }
    }
    
    public enum Action: Equatable, FeatureAction, BindableAction {
        public enum ViewAction: Equatable {
            case task
            case loadMoreIndicatorAppear
        }
        
        public enum ReducerAction {
            case loadMoreDays
        }
        
        public typealias DelegateAction = Never
        
        case binding(BindingAction<State>)
        case view(ViewAction)
        case reducer(ReducerAction)
        case delegate(DelegateAction)
    }
    
    @Dependency(\.reviewRequestService) var reviewRequestService
    @Dependency(\.calendar) var calendar
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    
    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.task):
                state.isOnTop = true
                state.offset = calendar.date(byAdding: .day, value: -4, to: now)
                loadDays(&state, count: 12)
                return .none
                
            case .view(.loadMoreIndicatorAppear):
                return .task {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    return .reducer(.loadMoreDays)
                }
                
            case .reducer(.loadMoreDays):
                loadDays(&state, count: 10)
                return .fireAndForget {
                    reviewRequestService.madeMeaningfulEvent(.moreScheduleRequested)
                }
                
            case .binding:
                return .none
            }
        }
        
        BindingReducer()
    }
    
    private func loadDays(_ state: inout State, count: Int) {
        guard
            let offset = state.offset,
                let start = calendar.date(byAdding: .day, value: 1, to: offset)
        else { return }
        
        let days = Array(state.weekSchedule.schedule(starting: start, now: now, calendar: calendar).prefix(count))

        if state.mostRelevant == nil {
            state.mostRelevant = days.first { $0.hasUnfinishedPairs(now: now) }?.date
        }

        state.offset = days.last?.date
        state.days.append(contentsOf: days.map { day(for: $0, isMostRelevant: $0.date == state.mostRelevant) })
    }
    
    private func day(
        for element: WeekSchedule.ScheduleElement,
        isMostRelevant: Bool
    ) -> ScheduleDayViewModel {
        return ScheduleDayViewModel(
            id: uuid(),
            title: String(localized: "screen.schedule.day.title.\(element.date.formatted(.scheduleDay)).\(element.weekNumber)"),
            subtitle: Self.relativeFormatter.relativeName(for: element.date, now: now),
            pairs: element.pairs.map(PairViewModel.init(pair:)),
            isToday: calendar.isDateInToday(element.date),
            isMostRelevant: isMostRelevant
        )
    }
    
    private static let relativeFormatter = RelativeDateTimeFormatter.relativeNameOnly()
}

private extension MeaningfulEvent {
    static let moreScheduleRequested = Self(score: 1)
}