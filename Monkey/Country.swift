//
//  Country.swift
//  Monkey
//
//  Created by Isaiah Turner on 8/27/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

/// An array of countries.
typealias Countries = [Country]

class Country: Equatable {
    /// The emoji flag for the country (e.g. "🇺🇸" for the United States).
    let emoji: String
    /// The calling code for the country (e.g. "1" for the United States).
    let code: String
    /// The ISO 3166-1 alpha-2 code for the country (e.g. "US" for the United States).
    let iso: String
    /// The name of the country (e.g. "United States" for the United States).
    let name: String
    /// An array of countries as read from the file, if file retrieval suceeded. This getter is very resource intensive; store the result.
    class var allCountries:Countries? {
      return self.allCountryData?.map({ Country(countryData: $0) }).sorted { (lhs, rhs) in
         return lhs.name < rhs.name
      }
    }
    /// The parsed contents of the country-data JSON file, if retrieval succeeded.
    private class var allCountryData:[[String: String]]? {
        guard let fileURL = Bundle.main.url(forResource: "country-data", withExtension: "json"),
            let data = try? Data(contentsOf: fileURL),
            let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: String]] else {
                print("Error: Unable to parse country data file.")
                return nil
        }
        return json
    }
   
    /// Initializes a country.
    ///
    /// - Parameter countryData: The country data from the country-data JSON file.
    private init(countryData: [String: String]) {
        self.code = countryData["code"] ?? ""
        self.emoji = countryData["emoji"] ?? ""
        self.iso = countryData["iso"] ?? ""
        self.name = countryData["name"] ?? ""
    }
   
   // MARK: Equatable
   /// Compares two countries based on ISO, calling code, and name.
   ///
   /// - Parameters:
   ///   - lhs: The left hand side of the comparison.
   ///   - rhs: The right hand side of the comparison.
   /// - Returns: Wether the two countries have the same ISO code.
   static func == (lhs: Country, rhs: Country) -> Bool {
      return lhs.code == rhs.code && lhs.iso == rhs.iso && lhs.name == rhs.name
   }
}

extension Array where Element == Country {
    /// Retrieves the first country in the array with the provided ISO.
    ///
    /// - Parameter iso: The ISO of the country to retrieve.
    /// - Returns: A country with the given ISO, if one exists.
    func country(withISO iso: String) -> Country? {
        return self.first { $0.iso == iso }
    }
   /// Retrieves the most likely Country in the array for the given ISO.
   ///
   /// - Parameter locale: The Locale to find a Country for.
   /// - Returns: The country for the provided Locale, if one is found.
    func country(forLocale locale: Locale) -> Country? {
        guard let iso = (locale as NSLocale).object(forKey: .countryCode) as? String else {
            return nil
        }
        return self.country(withISO: iso)
    }
}
