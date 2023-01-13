// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "KalturaPlayer",
    platforms: [.iOS(.v11),
                .tvOS(.v11)],
    products: [
        .library(name: "KalturaPlayer",
                 targets: ["KalturaPlayer"]),
        .library(name: "KalturaPlayerOTT",
                 targets: ["KalturaPlayerOTT", "Common", "KalturaPlayer"]),
        .library(name: "KalturaPlayerOVP",
                 targets: ["KalturaPlayerOVP", "Common", "KalturaPlayer"]),
        .library(name: "Interceptor",
                 targets: ["Interceptor"])
    ],
    dependencies: [
        .package(name: "PlayKit",
                 url: "https://github.com/kaltura/playkit-ios.git",
                 .upToNextMinor(from: "3.27.1")),
        .package(name: "PlayKitProviders",
                 url: "https://github.com/kaltura/playkit-ios-providers.git",
                 .upToNextMinor(from: "1.18.1")),
        .package(name: "PlayKitKava",
                 url: "https://github.com/kaltura/playkit-ios-kava.git",
                 .upToNextMinor(from: "1.10.1")),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.0.0")),
    ],
    targets: [
        
        .target(name: "Interceptor",
                dependencies: [
                    .product(name: "PlayKit", package: "PlayKit")
                ],
                path: "Sources/Interceptor/"),
        
        .target(name: "KalturaPlayer",
                dependencies: ["Interceptor"],
                path: "Sources/Player"),
        
        .target(name: "KalturaPlayerOTT",
                dependencies: [
                    "KalturaPlayer",
                    "Common",
                    .product(name: "PlayKitProviders", package: "PlayKitProviders"),
                    .product(name: "PlayKitKava", package: "PlayKitKava")
                ],
                path: "Sources/OTT",
                swiftSettings: [
                    .define("KalturaPlayerOTT_Package")
                ]),
        
        .target(name: "KalturaPlayerOVP",
                dependencies: [
                    "KalturaPlayer",
                    "Common",
                    .product(name: "PlayKitProviders", package: "PlayKitProviders"),
                    .product(name: "PlayKitKava", package: "PlayKitKava")
                ],
                path: "Sources/OVP",
                swiftSettings: [
                    .define("KalturaPlayerOVP_Package")
                ]),
        
        .target(name: "Common",
                dependencies: [
                    .product(name: "PlayKit", package: "PlayKit"),
                    .product(name: "PlayKitKava", package: "PlayKitKava")
                ],
                path: "Sources/Common"),
        
        .testTarget(name: "KalturaPlayerTests",
                    dependencies: [
                        "KalturaPlayer",
                        "Quick",
                        "Nimble"
                    ],
                    path: "Tests/Basic",
                    exclude: [])
    ]
//    swiftLanguageVersions: [
//            SwiftVersion.v5,
//        ]
)
