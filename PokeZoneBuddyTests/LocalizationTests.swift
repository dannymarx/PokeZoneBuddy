//
//  LocalizationTests.swift
//  PokeZoneBuddyTests
//
//  Created by Refactoring on 06.10.2025.
//

import XCTest
@testable import PokeZoneBuddy

final class LocalizationTests: XCTestCase {
    
    // MARK: - Test Data Structure
    
    struct LocalizableStrings: Codable {
        let sourceLanguage: String
        let strings: [String: StringEntry]
        let version: String
        
        struct StringEntry: Codable {
            let localizations: [String: Localization]
            let comment: String?
            
            struct Localization: Codable {
                let stringUnit: StringUnit
                
                struct StringUnit: Codable {
                    let state: String
                    let value: String
                }
            }
        }
    }
    
    // MARK: - Configuration
    
    var localizationFileURL: URL!
    var requiredLanguages: Set<String>!
    
    override func setUp() {
        super.setUp()
        
        // Path to Localizable.xcstrings
        let bundle = Bundle(for: type(of: self))
        guard let projectPath = bundle.resourcePath?.replacingOccurrences(of: "/PokeZoneBuddyTests.xctest/Contents/Resources", with: ""),
              let url = URL(string: "file://\(projectPath)/PokeZoneBuddy/Localization/Localizable.xcstrings") else {
            XCTFail("Could not find Localizable.xcstrings")
            return
        }
        
        localizationFileURL = url
        requiredLanguages = ["en", "de"]
    }
    
    // MARK: - Tests
    
    func testLocalizableFileExists() {
        XCTAssertNotNil(localizationFileURL, "Localizable.xcstrings file URL should not be nil")
        
        let fileExists = FileManager.default.fileExists(atPath: localizationFileURL.path)
        XCTAssertTrue(fileExists, "Localizable.xcstrings file should exist at \(localizationFileURL.path)")
    }
    
    func testLocalizableFileIsValidJSON() {
        guard let data = try? Data(contentsOf: localizationFileURL) else {
            XCTFail("Could not read Localizable.xcstrings")
            return
        }
        
        do {
            _ = try JSONDecoder().decode(LocalizableStrings.self, from: data)
        } catch {
            XCTFail("Localizable.xcstrings is not valid JSON: \(error)")
        }
    }
    
    func testAllKeysHaveRequiredLanguages() {
        guard let data = try? Data(contentsOf: localizationFileURL),
              let strings = try? JSONDecoder().decode(LocalizableStrings.self, from: data) else {
            XCTFail("Could not load Localizable.xcstrings")
            return
        }
        
        var missingTranslations: [String: Set<String>] = [:]
        
        for (key, entry) in strings.strings {
            let availableLanguages = Set(entry.localizations.keys)
            let missing = requiredLanguages.subtracting(availableLanguages)
            
            if !missing.isEmpty {
                missingTranslations[key] = missing
            }
        }
        
        if !missingTranslations.isEmpty {
            let report = missingTranslations.map { key, langs in
                "  - '\(key)': missing [\(langs.sorted().joined(separator: ", "))]"
            }.joined(separator: "\n")
            
            XCTFail("Found \(missingTranslations.count) keys with missing translations:\n\(report)")
        }
    }
    
    func testNoKeysHaveNewState() {
        guard let data = try? Data(contentsOf: localizationFileURL),
              let strings = try? JSONDecoder().decode(LocalizableStrings.self, from: data) else {
            XCTFail("Could not load Localizable.xcstrings")
            return
        }
        
        var keysWithNewState: [(String, String)] = []
        
        for (key, entry) in strings.strings {
            for (lang, localization) in entry.localizations {
                if localization.stringUnit.state == "new" {
                    keysWithNewState.append((key, lang))
                }
            }
        }
        
        if !keysWithNewState.isEmpty {
            let report = keysWithNewState.map { key, lang in
                "  - '\(key)' (\(lang))"
            }.joined(separator: "\n")
            
            XCTFail("Found \(keysWithNewState.count) translations with 'new' state:\n\(report)")
        }
    }
    
    func testNoValueEqualsKey() {
        guard let data = try? Data(contentsOf: localizationFileURL),
              let strings = try? JSONDecoder().decode(LocalizableStrings.self, from: data) else {
            XCTFail("Could not load Localizable.xcstrings")
            return
        }
        
        var keysMatchingValue: [(String, String)] = []
        
        for (key, entry) in strings.strings {
            for (lang, localization) in entry.localizations {
                let value = localization.stringUnit.value
                // Allow some exceptions for technical keys
                let isException = key.starts(with: "%") || key == "•"
                
                if !isException && value == key {
                    keysMatchingValue.append((key, lang))
                }
            }
        }
        
        if !keysMatchingValue.isEmpty {
            let report = keysMatchingValue.map { key, lang in
                "  - '\(key)' (\(lang))"
            }.joined(separator: "\n")
            
            XCTFail("Found \(keysMatchingValue.count) translations where value == key (potential placeholders):\n\(report)")
        }
    }
    
    func testAllTranslationsHaveValues() {
        guard let data = try? Data(contentsOf: localizationFileURL),
              let strings = try? JSONDecoder().decode(LocalizableStrings.self, from: data) else {
            XCTFail("Could not load Localizable.xcstrings")
            return
        }
        
        var emptyTranslations: [(String, String)] = []
        
        for (key, entry) in strings.strings {
            for (lang, localization) in entry.localizations {
                let value = localization.stringUnit.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if value.isEmpty {
                    emptyTranslations.append((key, lang))
                }
            }
        }
        
        if !emptyTranslations.isEmpty {
            let report = emptyTranslations.map { key, lang in
                "  - '\(key)' (\(lang))"
            }.joined(separator: "\n")
            
            XCTFail("Found \(emptyTranslations.count) empty translations:\n\(report)")
        }
    }
    
    func testLocalizationCoverage() {
        guard let data = try? Data(contentsOf: localizationFileURL),
              let strings = try? JSONDecoder().decode(LocalizableStrings.self, from: data) else {
            XCTFail("Could not load Localizable.xcstrings")
            return
        }
        
        let totalKeys = strings.strings.count
        var languageCoverage: [String: Int] = [:]
        
        for (_, entry) in strings.strings {
            for lang in requiredLanguages {
                if entry.localizations[lang] != nil {
                    languageCoverage[lang, default: 0] += 1
                }
            }
        }
        
        print("\n📊 Localization Coverage Report:")
        print("   Total keys: \(totalKeys)")
        
        for lang in requiredLanguages.sorted() {
            let count = languageCoverage[lang, default: 0]
            let percentage = Double(count) / Double(totalKeys) * 100.0
            print("   \(lang.uppercased()): \(count)/\(totalKeys) (\(String(format: "%.1f", percentage))%)")
            
            // Require 100% coverage
            XCTAssertEqual(count, totalKeys, "\(lang.uppercased()) should have 100% coverage")
        }
    }
    
    func testNoMixedLanguageTranslations() {
        guard let data = try? Data(contentsOf: localizationFileURL),
              let strings = try? JSONDecoder().decode(LocalizableStrings.self, from: data) else {
            XCTFail("Could not load Localizable.xcstrings")
            return
        }
        
        // Simple heuristic: DE translations shouldn't contain common English words
        let englishWords = ["To", "From", "The", "And", "Or", "Of", "In", "On", "At", "By"]
        var suspiciousTranslations: [(String, String)] = []
        
        for (key, entry) in strings.strings {
            if let deLocalization = entry.localizations["de"] {
                let value = deLocalization.stringUnit.value
                
                // Check for obvious English words in German translations
                for word in englishWords {
                    if value.contains(" \(word) ") || value.starts(with: "\(word) ") || value.hasSuffix(" \(word)") {
                        suspiciousTranslations.append((key, value))
                        break
                    }
                }
            }
        }
        
        if !suspiciousTranslations.isEmpty {
            let report = suspiciousTranslations.prefix(10).map { key, value in
                "  - '\(key)': \(value)"
            }.joined(separator: "\n")
            
            print("\n⚠️  Warning: Found \(suspiciousTranslations.count) potentially mixed DE/EN translations:")
            print(report)
            
            // Don't fail the test, just warn
            // XCTFail would be too strict for technical terms
        }
    }
}
