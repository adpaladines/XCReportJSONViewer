//
//  ContentView.swift
//  XCResultJsonViewer
//
//  Created by andres paladines on 1/31/25.
//

import SwiftUI
import Foundation

struct CoverageData: Codable {
    let coveredLines: Int
    let executableLines: Int
    let lineCoverage: Double
    let targets: [Target]
}

struct Target: Codable {
    let buildProductPath: String
        let coveredLines: Int
        let executableLines: Int
        let files: [File]
        let lineCoverage: Double
        let name: String
}

struct File: Codable {
    let coveredLines, executableLines: Int
    let functions: [Function]
    let lineCoverage: Double
    let name, path: String
}

struct Function: Codable {
    let coveredLines, executableLines, executionCount: Int
    let lineCoverage: Double
    let lineNumber: Int
    let name: String
}

class CoverageViewModel: ObservableObject {
    @Published var coverageData: CoverageData?
    
    func loadCoverageData(from fileURL: URL) {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            decodeJsonData(jsonData)
        } catch {
            print("Error reading file: \(error.localizedDescription)")
            return
        }
    }
    
    func decodeJsonData(_ jsonData: Data) {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(CoverageData.self, from: jsonData)
            DispatchQueue.main.async {
                self.coverageData = decodedData
            }
        } catch {
            print("Error al decodificar JSON: \(error)")
        }
    }
}

extension CoverageViewModel {
    func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["json"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let selectedFile = panel.url {
            loadCoverageData(from: selectedFile)
        }
    }
}

struct CoverageView: View {
    @StateObject var viewModel = CoverageViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("Select a JSON file") {
                viewModel.openFilePicker() // Usando NSOpenPanel
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if let data = viewModel.coverageData {
                Text("Code Coverage").font(.title).bold()
                Text("Covered lines: \(data.coveredLines)")
                Text("Executable lines: \(data.executableLines)")
                Text("Total Coverage: \(String(format: "%.2f", data.lineCoverage * 100))%")
                
                List(data.targets, id: \.buildProductPath) { target in
                    Section(
                        header:
                            Text("Target:")
                        + Text(target.buildProductPath.split(separator: "/").last.map(\.description) ?? target.buildProductPath)
                            .bold()
                    ) {
                        ForEach(target.files, id: \.name) { file in
                            VStack(alignment: .leading) {
                                Text(file.name).bold()
                                Text("Coverage: \(String(format: "%.2f", file.lineCoverage * 100))%")
                                Text("Covered lines: \(file.coveredLines) / \(file.executableLines)")
                            }
                        }
                    }
                }
            } else {
                Text("Select a JSON file to see the Code Coverage.")
            }
        }
        .padding()
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            CoverageView()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
