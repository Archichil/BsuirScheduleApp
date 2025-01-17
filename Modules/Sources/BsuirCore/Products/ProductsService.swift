import Foundation
import StoreKit
import Dependencies
import Combine

public protocol ProductsService {
    var tips: [Product] { get async }
    var subscription: Product { get async throws }
    var subscriptionStatus: Product.SubscriptionInfo.Status? { get async }

    func load()
    @discardableResult
    func purchase(_ product: Product) async throws -> Bool
    func restore() async
}

// MARK: - Dependency

extension DependencyValues {
    public var productsService: ProductsService {
        get { self[ProductsServiceKey.self] }
        set { self[ProductsServiceKey.self] = newValue }
    }
}

private enum ProductsServiceKey: DependencyKey {
    public static let liveValue: any ProductsService = {
        @Dependency(\.widgetService) var widgetService
        return LiveProductsService(widgetService: widgetService)
    }()

    public static let previewValue: any ProductsService = ProductsServiceMock()
}

// MARK: - Mock

final class ProductsServiceMock: ProductsService {
    enum Failure: Error {
        case notImplemented
    }

    var tips: [Product] {
        get async { [] }
    }

    var subscription: Product {
        get async throws { throw Failure.notImplemented }
    }

    var subscriptionStatus: Product.SubscriptionInfo.Status? {
        get async { nil }
    }

    func load() {}
    func purchase(_ product: Product) async throws -> Bool { false }
    func restore() async {}
}
