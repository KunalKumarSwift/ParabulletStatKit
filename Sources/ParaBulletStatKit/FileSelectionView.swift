//
//  FileSelectionView.swift
//
//
//  Created by Kunal Kumar on 2024-08-29.
//

import CoreXLSX
import SwiftUI
import CoreXLSX
import UniformTypeIdentifiers

public struct FileSelectionView: View {
    @State private var isFileImporterPresented = false
    @State private var selectedData: [Double] = []
    @EnvironmentObject private var calculator: StatisticsCalculator

    public init() {}  // Public initializer

    // Define the UTType for .xlsx files
        let excelFileType = UTType(filenameExtension: "xlsx", conformingTo: .data)!

    public var body: some View {
        NavigationView {
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
                    handleFileSelection(result: result)
                }
                .padding()

                if !selectedData.isEmpty {
                    NavigationLink(destination: StatisticsView(calculator: calculator)) {
                                        Text("View Stats")
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .padding(.top)

                } else {
                    Text("No data loaded. Please select an Excel file.")
                        .foregroundColor(.gray)
                }
                NavigationLink(destination: StatisticsView(calculator: calculator)) {
                                    Text("View Stats")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(32)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.top)

                NavigationLink(destination: HistogramView(calculator: calculator)) {
                                    Text("View Histogram")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(32)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.top)

                NavigationLink(destination: CLTView(statisticsCalculator: calculator)) {
                                    Text("View CLT")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(32)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.top)
            }
            .padding()
        }
    }

    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let fileURL = urls.first {
                loadDataFromExcel(fileURL: fileURL)
            }
        case .failure(let error):
            print("Failed to load file: \(error.localizedDescription)")
        }
    }

    private func loadDataFromExcel(fileURL: URL) {

        guard fileURL.startAccessingSecurityScopedResource() else {
                print("Failed to access security-scoped resource.")
                return
            }

            defer {
                // Ensure that the resource is released when done
                fileURL.stopAccessingSecurityScopedResource()
            }
        //printFileContents(fileURL: fileURL)
        do {
            let fileData = try Data(contentsOf: fileURL)
            let file = try XLSXFile(data: fileData)
            guard let worksheet = try file.parseWorksheetPaths().first else {
                return
            }
            let worksheetData = try file.parseWorksheet(at: worksheet)
            var columnData: [Double] = []

            print(worksheetData.data?.rows.publisher.values ?? "NA")

//            for row in worksheetData.data?.rows ?? [] {
//                // Assuming you want the first column
//                if let cell = row.cells.first, let value = cell.stringValue(sharedStrings), let doubleValue = Double(value) {
//                    columnData.append(doubleValue)
//                }
//            }

            selectedData = columnData
            calculator.data = selectedData
        } catch {
            print("Error reading Excel file: \(error.localizedDescription)")
        }
    }

    func printFileContents(fileURL: URL) {
        do {
            // Read the file contents as a string
            let fileContents = try Data(contentsOf: fileURL)//String(contentsOf: fileURL, encoding: .utf8)

            // Print the contents to the console
            print(fileContents)
        } catch {
            // Handle any errors that may occur
            print("Error reading file: \(error.localizedDescription)")
        }
    }
}

struct FileSelectionView_Previews: PreviewProvider {
    
    static var previews: some View {
        // Create a mock StatisticsCalculator for the preview

        // Create a FileSelectionView with the mock calculator
        FileSelectionView()
            .environmentObject(statisticsCalculator) // Use .environmentObject to inject the mock calculator
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
