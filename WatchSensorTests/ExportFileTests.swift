//
//  ExportFileTests.swift
//  WatchSensorTests
//
//  Created by 上別縄祐也 on 2022/07/15.
//

import XCTest
@testable import WatchSensor

class ExportFileTests: XCTestCase {
    let exportFile = ExportFile()

    func testExportFiles() {
        XCTAssertTrue(exportFile.exportFiles(fileInfo: FileInfo.mock1))
    }
    
    func testCreateDirectory() {
        XCTAssertTrue(exportFile.createDirectory(directory: DirectoryInfoMock.mock1.directoryName))
    }
    
    func testExportFile() {
        XCTAssertTrue(exportFile.exportFile(directory: DirectoryInfoMock.mock1.directoryName, Info: FileInfo.mock1.sensorInfo))
    }

}
