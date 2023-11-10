import Foundation
import BsuirCore
import BsuirUI
import BsuirApi
import ComposableArchitecture
import URLRouting

public struct LoadingError: Reducer {
    public enum State: Equatable {
        case unknown
        case notConnectedToInternet
        case failedToDecode(LoadingErrorFailedToDecode.State)
        case noSchedule
        case somethingWrongWithBsuir(LoadingErrorSomethingWrongWithBsuir.State)
    }

    public enum Action: Equatable {
        case reload
        case unknown(LoadingErrorUnknown.Action)
        case notConnectedToInternet(LoadingErrorNotConnectedToInternet.Action)
        case failedToDecode(LoadingErrorFailedToDecode.Action)
        case noSchedule(LoadingErrorNoSchedule.Action)
        case somethingWrongWithBsuir(LoadingErrorSomethingWrongWithBsuir.Action)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .somethingWrongWithBsuir(.reloadButtonTapped),
                 .notConnectedToInternet(.reloadButtonTapped),
                 .noSchedule(.reloadButtonTapped),
                 .unknown(.reloadButtonTapped):
                return .send(.reload)
            case .reload,
                 .failedToDecode(.openIssueTapped),
                 .somethingWrongWithBsuir(.reachability),
                 .somethingWrongWithBsuir(.openIssueTapped):
                return .none
            }
        }
        .ifCaseLet(/State.unknown, action: /Action.unknown) {
            LoadingErrorUnknown()
        }
        .ifCaseLet(/State.failedToDecode, action: /Action.failedToDecode) {
            LoadingErrorFailedToDecode()
        }
        .ifCaseLet(/State.somethingWrongWithBsuir, action: /Action.somethingWrongWithBsuir) {
            LoadingErrorSomethingWrongWithBsuir()
        }
        .ifCaseLet(/State.noSchedule, action: /Action.noSchedule) {
            LoadingErrorNoSchedule()
        }
        .ifCaseLet(/State.notConnectedToInternet, action: /Action.notConnectedToInternet) {
            LoadingErrorNotConnectedToInternet()
        }
    }
}

// MARK: - Decode

extension LoadingError.State {
    init(_ error: Error) {
        switch error {
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet, .timedOut, .networkConnectionLost, .dataNotAllowed:
                self = .notConnectedToInternet
            default:
                assertionFailure("Unknown url error code \(urlError.code)")
                self = .unknown
            }
        case let decodingError as MyURLRoutingDecodingError:
            let url = decodingError.response.url
            let description = String(describing: decodingError.underlyingError)

            switch (decodingError.response as? HTTPURLResponse)?.statusCode ?? 0 {
            case 200..<300:
                self = .failedToDecode(.init(url: url, description: description))
            case 404:
                self = .noSchedule
            case let statusCode:
                self = .somethingWrongWithBsuir(.init(url: url, description: description, statusCode: statusCode))
            }
        default:
            assertionFailure("Unknown error type \(error)")
            self = .unknown
        }
    }
}
