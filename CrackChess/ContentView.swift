//
//  ContentView.swift
//  CrackChess
//
//  Created by stone on 2025/11/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            testM2()
        }
    }
    
}

#Preview {
    ContentView()
}

extension ContentView {
    func testM1() {// 在测试函数中调用
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outDir = docs.appendingPathComponent("DatasetOut", isDirectory: true)
        
        // 加载 M2 结果图
        let path = "/Users/you/Documents/M2TestOut/final_warped.png"
        let url = URL(fileURLWithPath: path)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            fatalError("Cannot load warped image")
        }
        
        // 自动分格与标签生成
        do {
            try DatasetBuilder.generateDataset(from: cg, outputDir: outDir)
        } catch {
            fputs("❌ M3Test failed: \(error)\n", stderr)
            exit(1)
        }
    }
    
    func testM2() {
        let fm = FileManager.default
        let docsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outDir = docsURL.appendingPathComponent("M2TestOut", isDirectory: true)
        
        // ensure output directory exists
        try? fm.createDirectory(at: outDir, withIntermediateDirectories: true)
        
        print("Running StageM2Pipeline with asset image 'blackBottom'...")
        print("Output dir:", outDir.path)
        
        do {
            try StageM2Pipeline.run(imageName: "blackBottom", debugOut: outDir.path)
            print("✅ M2Test finished. Check output in:", outDir.path)
//            testM3()
        } catch {
            fputs("❌ M2Test failed: \(error)\n", stderr)
            exit(1)
        }
    }
    
    func testM3() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let inputRoot  = URL(fileURLWithPath: "\(docs.path)/M2TestOut", isDirectory: true)
        let outputRoot = URL(fileURLWithPath: "\(docs.path)/AllDatasets", isDirectory: true)
        
        do {
            try DatasetBuilder.batchGenerate(
                fromDir: inputRoot,
                outputRoot: outputRoot,
                pattern: "final_warped.png",
                recursive: true,
                boardSize: 1024,
                patchSize: 32,
                thresholdBrightness: 0.15,
                thresholdEdge: 0.08,
                emitDebugOverlay: true
            )
        } catch {
            fputs("❌ M3Test failed: \(error)\n", stderr)
            exit(1)
        }
        
    }
}
