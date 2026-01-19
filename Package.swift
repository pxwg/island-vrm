// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IslandVRM",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // 1. 库产品：Xcode 可以在这里进行 Canvas 预览
        .library(name: "IslandCore", targets: ["IslandCore"]),
        // 2. 可执行产品：用于实际运行 App
        .executable(name: "IslandApp", targets: ["IslandApp"]),
    ],
    targets: [
        // --- 核心逻辑库 (支持预览) ---
        .target(
            name: "IslandCore",
            path: "Core", // 指向刚才创建的文件夹
            resources: [
                // 假设 WebResources 在根目录，我们需要让它能在 Core 里被访问
                // 如果 WebResources 还在根目录，建议也移入 Core 或者用相对路径引用
                .copy("../WebResources"),
            ]
        ),

        // --- App 入口 (依赖核心库) ---
        .executableTarget(
            name: "IslandApp",
            dependencies: ["IslandCore"], // 链接核心逻辑
            path: ".", // 根目录
            sources: ["IslandApp.swift"] // 只包含入口文件
        ),
    ]
)
