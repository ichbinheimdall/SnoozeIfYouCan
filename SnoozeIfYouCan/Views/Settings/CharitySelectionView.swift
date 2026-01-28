import SwiftUI

// MARK: - Charity Selection View

struct CharitySelectionView: View {
    @EnvironmentObject var charityManager: CharityManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: Charity.CharityCategory?
    @State private var searchText = ""
    
    private var filteredCharities: [Charity] {
        var charities = charityManager.availableCharities
        
        if let category = selectedCategory {
            charities = charities.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            charities = charities.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.shortName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return charities
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .searchable(text: $searchText, prompt: "Search charities")
                .navigationTitle("Choose Charity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Selection Header
                CurrentCharityCard(charity: charityManager.selectedCharity)
                    .padding(.horizontal)
                
                // Category Filter
                CategoryFilterView(selectedCategory: $selectedCategory)
                
                // Charity List
                charityListView
            }
            .padding(.vertical)
        }
    }
    
    private var charityListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredCharities) { charity in
                CharityCard(
                    charity: charity,
                    isSelected: charityManager.selectedCharity.id == charity.id,
                    donated: charityManager.totalDonated(to: charity)
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        charityManager.selectCharity(charity)
                        HapticsManager.shared.selectionChanged()
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Current Charity Card

struct CurrentCharityCard: View {
    let charity: Charity
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Your donations go to")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(charity.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: charity.category.icon)
                        .font(.title2)
                        .foregroundStyle(charity.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(charity.name)
                        .font(.headline)
                    Text(charity.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Category Filter View

struct CategoryFilterView: View {
    @Binding var selectedCategory: Charity.CharityCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    icon: "globe",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation { selectedCategory = nil }
                }
                
                ForEach(Charity.CharityCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation { selectedCategory = category }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color.secondary.opacity(0.15))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Charity Card

struct CharityCard: View {
    let charity: Charity
    let isSelected: Bool
    let donated: Double
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Logo/Icon
                ZStack {
                    Circle()
                        .fill(charity.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: charity.category.icon)
                        .font(.title2)
                        .foregroundStyle(charity.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(charity.shortName)
                            .font(.headline)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Text(charity.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if donated > 0 {
                        Text("You've donated $\(String(format: "%.2f", donated))")
                            .font(.caption2)
                            .foregroundStyle(charity.color)
                    }
                }
                
                Spacer()
                
                // Country Flag
                Text(charity.country)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? charity.color.opacity(0.1) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? charity.color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Charity Detail Sheet

struct CharityDetailSheet: View {
    let charity: Charity
    @EnvironmentObject var charityManager: CharityManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(charity.color.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: charity.category.icon)
                                .font(.system(size: 44))
                                .foregroundStyle(charity.color)
                        }
                        
                        Text(charity.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        HStack {
                            Label(charity.category.rawValue, systemImage: charity.category.icon)
                            Text("•")
                            Text(charity.country)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    // Description
                    Text(charity.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    // Stats
                    if charityManager.totalDonated(to: charity) > 0 {
                        VStack(spacing: 8) {
                            Text("Your Impact")
                                .font(.headline)
                            
                            Text("$\(String(format: "%.2f", charityManager.totalDonated(to: charity)))")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(charity.color)
                            
                            Text("donated through snoozing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(charity.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    // Website Link
                    if let url = charity.websiteURL {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Visit Website")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(charity.color)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Select Button
                    Button {
                        charityManager.selectCharity(charity)
                        HapticsManager.shared.success()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: charityManager.selectedCharity.id == charity.id ? "checkmark.circle.fill" : "heart.fill")
                            Text(charityManager.selectedCharity.id == charity.id ? "Currently Selected" : "Select This Charity")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(charityManager.selectedCharity.id == charity.id ? .green : .orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .disabled(charityManager.selectedCharity.id == charity.id)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CharitySelectionView()
        .environmentObject(CharityManager.shared)
}
