// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BsuirScheduleApp",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Features",
            targets: [
                "AboutFeature",
                "GroupsFeature",
                "LecturersFeature",
                "ScheduleFeature",
                "LoadableFeature",
                "Deeplinking"
            ]),
        .library(
            name: "AboutFeature",
            targets: ["AboutFeature"]),
        .library(
            name: "GroupsFeature",
            targets: ["GroupsFeature"]),
        .library(
            name: "LecturersFeature",
            targets: ["LecturersFeature"]),
        .library(
            name: "EntityScheduleFeature",
            targets: ["ScheduleFeature"]),
        .library(
            name: "ScheduleFeature",
            targets: ["ScheduleFeature"]),
        .library(
            name: "LoadableFeature",
            targets: ["LoadableFeature"]),
        .library(
            name: "BsuirUI",
            targets: ["BsuirUI"]),
        .library(
            name: "BsuirCore",
            targets: ["BsuirCore"]),
        .library(
            name: "BsuirApi",
            targets: ["BsuirApi"]),
        .library(
            name: "Deeplinking",
            targets: ["Deeplinking"]),
    ],
    dependencies: [
         .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
         .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "0.46.0"),
         .package(url: "https://github.com/pointfreeco/swift-url-routing.git", from: "0.4.0")
    ],
    targets: [
        // MARK: - Features
        .target(
            name: "AboutFeature",
            dependencies: ["BsuirCore", "BsuirUI", "ComposableArchitectureUtils", .tca, .tcaDependencies]
        ),
        .target(
            name: "GroupsFeature",
            dependencies: ["EntityScheduleFeature", "LoadableFeature", "Favorites", "BsuirApi", "BsuirCore", "BsuirUI", "ComposableArchitectureUtils", .tca]
        ),
        .target(
            name: "LecturersFeature",
            dependencies: ["EntityScheduleFeature", "LoadableFeature", "Favorites", "BsuirCore", "BsuirUI", "ComposableArchitectureUtils", .tca]
        ),
        .target(
            name: "EntityScheduleFeature",
            dependencies: ["ScheduleFeature", "LoadableFeature", "Favorites", "BsuirCore", "BsuirUI", "ComposableArchitectureUtils", .tca]
        ),
        .target(
            name: "ScheduleFeature",
            dependencies: ["LoadableFeature", "Favorites", "BsuirCore", "BsuirUI", "ComposableArchitectureUtils", .tca]
        ),
        .target(
            name: "LoadableFeature",
            dependencies: ["ComposableArchitectureUtils", .tca]
        ),
        .target(
            name: "Favorites",
            dependencies: ["BsuirApi", .tcaDependencies]
        ),
        .target(
            name: "Deeplinking",
            dependencies: [.urlRouting, .tcaDependencies]
        ),
        // MARK: - Core
        .target(
            name: "ComposableArchitectureUtils",
            dependencies: [.tca]),
        .target(
            name: "BsuirUI",
            dependencies: ["BsuirApi", "BsuirCore", "Kingfisher", .tcaDependencies]),
        .target(
            name: "BsuirCore",
            dependencies: ["BsuirApi", .tcaDependencies]),
        .target(
            name: "BsuirApi",
            dependencies: [.urlRouting, .tcaDependencies]),
        .testTarget(
            name: "BsuirCoreTests",
            dependencies: ["BsuirCore"]),
        .testTarget(
            name: "BsuirApiTests",
            dependencies: ["BsuirApi"],
            resources: [.process("jsons")]),
    ]
)

private extension Target.Dependency {
    static let urlRouting: Self = .product(name: "URLRouting", package: "swift-url-routing")
    static let tca: Self = .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
    static let tcaDependencies: Self = .product(name: "Dependencies", package: "swift-composable-architecture")
}
