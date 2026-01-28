import Foundation
import SwiftUI
import Combine

// MARK: - Charity Model

struct Charity: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let description: String
    let category: CharityCategory
    let websiteURL: URL?
    let logoName: String
    let accentColor: String
    let country: String
    
    var color: Color {
        switch accentColor {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        default: return .blue
        }
    }
    
    enum CharityCategory: String, Codable, CaseIterable {
        case education = "Education"
        case health = "Health"
        case environment = "Environment"
        case children = "Children"
        case animals = "Animals"
        case humanitarian = "Humanitarian"
        
        var icon: String {
            switch self {
            case .education: return "book.fill"
            case .health: return "heart.fill"
            case .environment: return "leaf.fill"
            case .children: return "figure.2.and.child.holdinghands"
            case .animals: return "pawprint.fill"
            case .humanitarian: return "hands.sparkles.fill"
            }
        }
    }
}

// MARK: - Charity Manager

@MainActor
class CharityManager: ObservableObject {
    static let shared = CharityManager()
    
    @Published var availableCharities: [Charity] = []
    @Published var selectedCharity: Charity
    @Published var totalDonatedByCharity: [String: Double] = [:]
    
    private let selectedCharityKey = "selected_charity_id"
    private let donationsByCharityKey = "donations_by_charity"
    
    private init() {
        // Initialize with default charity
        let defaultCharity = Self.defaultCharities[0]
        self.selectedCharity = defaultCharity
        self.availableCharities = Self.defaultCharities
        
        loadSavedCharity()
        loadDonationHistory()
    }
    
    private func loadSavedCharity() {
        if let savedID = UserDefaults.standard.string(forKey: selectedCharityKey),
           let charity = availableCharities.first(where: { $0.id == savedID }) {
            selectedCharity = charity
        }
    }
    
    private func loadDonationHistory() {
        if let data = UserDefaults.standard.data(forKey: donationsByCharityKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            totalDonatedByCharity = decoded
        }
    }
    
    func selectCharity(_ charity: Charity) {
        selectedCharity = charity
        UserDefaults.standard.set(charity.id, forKey: selectedCharityKey)
    }
    
    func recordDonation(amount: Double) {
        let charityID = selectedCharity.id
        totalDonatedByCharity[charityID, default: 0] += amount
        
        if let encoded = try? JSONEncoder().encode(totalDonatedByCharity) {
            UserDefaults.standard.set(encoded, forKey: donationsByCharityKey)
        }
    }
    
    func totalDonated(to charity: Charity) -> Double {
        totalDonatedByCharity[charity.id] ?? 0
    }
    
    var totalDonatedAllCharities: Double {
        totalDonatedByCharity.values.reduce(0, +)
    }
    
    // MARK: - Default Charities
    
    static let defaultCharities: [Charity] = [
        Charity(
            id: "darussafaka",
            name: "Darüşşafaka Cemiyeti",
            shortName: "Darüşşafaka",
            description: "Since 1863, Darüşşafaka has provided free education to orphaned children in Turkey, giving them opportunities for a brighter future.",
            category: .education,
            websiteURL: URL(string: "https://www.darussafaka.org"),
            logoName: "darussafaka_logo",
            accentColor: "blue",
            country: "Turkey"
        ),
        Charity(
            id: "unicef",
            name: "UNICEF",
            shortName: "UNICEF",
            description: "UNICEF works in over 190 countries to save children's lives, defend their rights, and help them fulfill their potential.",
            category: .children,
            websiteURL: URL(string: "https://www.unicef.org"),
            logoName: "unicef_logo",
            accentColor: "blue",
            country: "International"
        ),
        Charity(
            id: "wwf",
            name: "World Wildlife Fund",
            shortName: "WWF",
            description: "WWF works to conserve nature and reduce the most pressing threats to the diversity of life on Earth.",
            category: .environment,
            websiteURL: URL(string: "https://www.worldwildlife.org"),
            logoName: "wwf_logo",
            accentColor: "green",
            country: "International"
        ),
        Charity(
            id: "stjude",
            name: "St. Jude Children's Research Hospital",
            shortName: "St. Jude",
            description: "St. Jude is leading the way the world understands, treats and defeats childhood cancer and other life-threatening diseases.",
            category: .health,
            websiteURL: URL(string: "https://www.stjude.org"),
            logoName: "stjude_logo",
            accentColor: "red",
            country: "USA"
        ),
        Charity(
            id: "redcross",
            name: "International Red Cross",
            shortName: "Red Cross",
            description: "The Red Cross provides emergency assistance, disaster relief, and disaster preparedness education worldwide.",
            category: .humanitarian,
            websiteURL: URL(string: "https://www.icrc.org"),
            logoName: "redcross_logo",
            accentColor: "red",
            country: "International"
        ),
        Charity(
            id: "aspca",
            name: "ASPCA",
            shortName: "ASPCA",
            description: "The ASPCA works to rescue animals from abuse, pass humane laws, and share resources with shelters nationwide.",
            category: .animals,
            websiteURL: URL(string: "https://www.aspca.org"),
            logoName: "aspca_logo",
            accentColor: "orange",
            country: "USA"
        ),
        Charity(
            id: "feedingamerica",
            name: "Feeding America",
            shortName: "Feeding America",
            description: "Feeding America is the largest hunger-relief organization in the United States, providing meals to millions.",
            category: .humanitarian,
            websiteURL: URL(string: "https://www.feedingamerica.org"),
            logoName: "feedingamerica_logo",
            accentColor: "orange",
            country: "USA"
        ),
        Charity(
            id: "doctorswithoutborders",
            name: "Doctors Without Borders",
            shortName: "MSF",
            description: "MSF provides medical humanitarian aid to people affected by conflict, epidemics, disasters, or exclusion from healthcare.",
            category: .health,
            websiteURL: URL(string: "https://www.doctorswithoutborders.org"),
            logoName: "msf_logo",
            accentColor: "red",
            country: "International"
        )
    ]
}
