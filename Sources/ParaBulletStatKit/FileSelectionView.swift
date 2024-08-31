//
//  FileSelectionView.swift
//
//
//  Created by Kunal Kumar on 2024-08-29.
//
import CoreXLSX
import SwiftUI
import UniformTypeIdentifiers

public struct FileSelectionView: View {
    @State private var isFileImporterPresented = false
    @State private var isLoading = false // Loading state
    @State private var selectedData: [Double] = []
    @EnvironmentObject private var calculator: StatisticsCalculator

    public init() {}  // Public initializer

    let excelFileType = UTType(filenameExtension: "xlsx", conformingTo: .data)!

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button("Select Excel File") {
                    isFileImporterPresented = true
                }
                .buttonStyle(.borderedProminent)
                .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: [.data],
                    allowsMultipleSelection: false
                ) { result in
                    Task {
                        isLoading = true // Start loading
                        await handleFileSelection(result: result)
                        isLoading = false // Stop loading
                    }
                }
                .padding()

                if isLoading {
                    ProgressView("Loading data...")
                        .padding()
                } else if selectedData.isEmpty {
                    Text("No data loaded. Please select an Excel file.")
                        .foregroundColor(.gray)
                }

                VStack {
                    NavigationLink(destination: AnyView(StatisticsView(calculator: calculator))) {
                        Text("View Stats")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(32)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top)

                    NavigationLink(destination: AnyView(HistogramView(calculator: calculator))) {
                        Text("View Histogram")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(32)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top)

                    NavigationLink(destination: AnyView(CLTView(statisticsCalculator: calculator))) {
                        Text("View CLT")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(32)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
    }

    private func handleFileSelection(result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            if let fileURL = urls.first {
                await loadDataFromExcel(fileURL: fileURL)
            }
        case .failure(let error):
            print("Failed to load file: \(error.localizedDescription)")
        }
    }

    private func loadDataFromExcel(fileURL: URL) async {
        guard fileURL.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource.")
            return
        }

        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }

        do {
            let fileData = try Data(contentsOf: fileURL)
            let file = try XLSXFile(data: fileData)
            guard let worksheet = try file.parseWorksheetPaths().first else {
                return
            }
            let worksheetData = try file.parseWorksheet(at: worksheet)
            var columnData: [Double] = []

            for row in worksheetData.data?.rows ?? [] {
                if let cell = row.cells.first,
                   let value = cell.value,
                   let doubleValue = Double(value) {
                    columnData.append(doubleValue)
                }
            }

            await MainActor.run {
                self.selectedData = columnData
                self.calculator.data = self.selectedData
            }
        } catch {
            print("Error reading Excel file: \(error.localizedDescription)")
        }
    }
}

struct FileSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let statisticsCalculator = StatisticsCalculator()

        FileSelectionView()
            .environmentObject(statisticsCalculator)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
