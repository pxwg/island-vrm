// main.swift
import Cocoa
import SwiftUI

// 1. 绑定 Delegate
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2. 启动应用
app.run()
