// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "KalturaPlayer",
    platforms: [.iOS(.v11),
                .tvOS(.v11)],
    products: [
        .library(name: "KalturaPlayer",
                 targets: ["KalturaPlayer", "Interceptor"]),
//               .library(name: "KalturaPlayerOTT",
//                        targets: ["KalturaPlayerOTT"]),
//               .library(name: "KalturaPlayerOVP",
//                        targets: ["KalturaPlayerOVP"]),
        .library(name: "Interceptor",
                 targets: ["Interceptor"])
    ],
    dependencies: [
        .package(name: "PlayKit",
                 url: "https://github.com/kaltura/playkit-ios.git",
                 .branch("FEC-12640")),
        .package(name: "PlayKitProviders",
                 url: "https://github.com/kaltura/playkit-ios-providers.git",
                 .branch("FEC-12640")),
        .package(name: "PlayKitKava",
                 url: "https://github.com/kaltura/playkit-ios-kava.git",
                 .branch("FEC-12640")),
    ],
    targets: [
        .target(name: "Interceptor",
                dependencies: [
                    .product(name: "PlayKit", package: "PlayKit")
                ],
                path: "Sources/Interceptor/"),
        .target(name: "KalturaPlayer",
                dependencies: [
                    "Interceptor"
                ],
                path: "Sources/",
                exclude: ["Interceptor/", "OTT/", "OVP/", "Common/", "Offline/", "UI/"]),
//        .target(name: "KalturaPlayerOTT",
//                dependencies: [
//                    "KalturaPlayer",
//                    .product(name: "PlayKitProviders", package: "PlayKitProviders"),
//                    .product(name: "PlayKitKava", package: "PlayKitKava")
//                ],
//                path: "Sources/",
//                sources: ["Sources/Common/", "Sources/OTT/"],
//                resources: [
//                    .process("Sources/OTT/KPOTTDMSConfigModel.xcdatamodeld")]),
//        .target(name: "KalturaPlayerOVP",
//                dependencies: [
//                    "KalturaPlayer",
//                    .product(name: "PlayKitProviders", package: "PlayKitProviders"),
//                    .product(name: "PlayKitKava", package: "PlayKitKava")
//                ],
//                path: "Sources/",
//                sources: ["Sources/Common/", "Sources/OVP/"],
//                resources: [
//                    .process("Sources/OVP/KPOVPConfigModel.xcdatamodeld")]),
    ]
//    swiftLanguageVersions: [
//            SwiftVersion.v5,
//        ]
)
