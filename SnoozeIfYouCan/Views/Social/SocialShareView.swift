import SwiftUI
import UIKit

// MARK: - Social Share View

struct SocialShareView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @EnvironmentObject var charityManager: CharityManager
    @State private var selectedTemplate: ShareTemplate = .impact
    @State private var showShareSheet = false
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Card
                    SharePreviewCard(
                        template: selectedTemplate,
                        stats: alarmManager.stats,
                        charity: charityManager.selectedCharity
                    )
                    .padding(.horizontal)
                    
                    // Template Selector
                    TemplateSelectorView(selectedTemplate: $selectedTemplate)
                    
                    // Share Buttons
                    ShareButtonsSection(
                        onInstagram: shareToInstagram,
                        onSnapchat: shareToSnapchat,
                        onMore: { showShareSheet = true },
                        isGenerating: isGenerating
                    )
                    
                    // Info
                    InfoSection()
                }
                .padding(.vertical)
            }
            .navigationTitle("Share Impact")
            .sheet(isPresented: $showShareSheet) {
                if let image = generatedImage {
                    ShareSheetView(items: [image])
                }
            }
        }
    }
    
    private func shareToInstagram() {
        isGenerating = true
        
        Task {
            let image = await generateShareImage()
            generatedImage = image
            
            // Open Instagram Stories
            if let storiesUrl = URL(string: "instagram-stories://share"),
               UIApplication.shared.canOpenURL(storiesUrl),
               let imageData = image.pngData() {
                
                let pasteboardItems: [String: Any] = [
                    "com.instagram.sharedSticker.stickerImage": imageData,
                    "com.instagram.sharedSticker.backgroundTopColor": "#FF9500",
                    "com.instagram.sharedSticker.backgroundBottomColor": "#FF6B00"
                ]
                
                UIPasteboard.general.setItems([pasteboardItems], options: [:])
                await UIApplication.shared.open(storiesUrl)
                
                // Mark as shared for achievement
                UserDefaults.standard.set(true, forKey: "has_shared_socially")
            } else {
                // Fallback to share sheet
                showShareSheet = true
            }
            
            isGenerating = false
        }
    }
    
    private func shareToSnapchat() {
        isGenerating = true
        
        Task {
            let image = await generateShareImage()
            generatedImage = image
            
            // Try Snapchat Creative Kit
            if let snapchatURL = URL(string: "snapchat://"),
               UIApplication.shared.canOpenURL(snapchatURL),
               let _ = image.pngData() {
                
                // Save to camera roll and open Snapchat
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                await UIApplication.shared.open(snapchatURL)
                
                // Mark as shared for achievement
                UserDefaults.standard.set(true, forKey: "has_shared_socially")
            } else {
                showShareSheet = true
            }
            
            isGenerating = false
        }
    }
    
    @MainActor
    private func generateShareImage() async -> UIImage {
        let renderer = ImageRenderer(content:
            ShareImageContent(
                template: selectedTemplate,
                stats: alarmManager.stats,
                charity: charityManager.selectedCharity
            )
            .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1.0
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - Share Templates

enum ShareTemplate: String, CaseIterable, Identifiable {
    case impact = "My Impact"
    case streak = "Streak"
    case donation = "Donation"
    case milestone = "Milestone"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .impact: return "heart.circle.fill"
        case .streak: return "flame.fill"
        case .donation: return "dollarsign.circle.fill"
        case .milestone: return "trophy.fill"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .impact: return [.pink, .orange]
        case .streak: return [.orange, .red]
        case .donation: return [.green, .mint]
        case .milestone: return [.purple, .indigo]
        }
    }
}

// MARK: - Share Preview Card

struct SharePreviewCard: View {
    let template: ShareTemplate
    let stats: DonationStats
    let charity: Charity
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: template.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 20) {
                // App branding
                HStack {
                    Image(systemName: "alarm.fill")
                    Text("Snooze If You Can")
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white.opacity(0.9))
                .font(.subheadline)
                
                Spacer()
                
                // Main content based on template
                switch template {
                case .impact:
                    ImpactTemplateContent(stats: stats, charity: charity)
                case .streak:
                    StreakTemplateContent(stats: stats)
                case .donation:
                    DonationTemplateContent(stats: stats, charity: charity)
                case .milestone:
                    MilestoneTemplateContent(stats: stats)
                }
                
                Spacer()
                
                // CTA
                Text("Download & make a difference!")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(24)
        }
        .frame(height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }
}

struct ImpactTemplateContent: View {
    let stats: DonationStats
    let charity: Charity
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            
            Text("My Impact")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            VStack(spacing: 8) {
                Text("$\(String(format: "%.2f", stats.totalDonated))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("donated to \(charity.shortName)")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            HStack(spacing: 24) {
                StatBubble(value: "\(stats.currentStreak)", label: "Day Streak")
                StatBubble(value: "\(stats.totalSnoozes)", label: "Snoozes")
            }
        }
    }
}

struct StreakTemplateContent: View {
    let stats: DonationStats
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white)
            
            Text("\(stats.currentStreak)")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(.white)
            
            Text("Day Streak!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Waking up without snoozing")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

struct DonationTemplateContent: View {
    let stats: DonationStats
    let charity: Charity
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: charity.category.icon)
                .font(.system(size: 60))
                .foregroundStyle(.white)
            
            Text("Proud Supporter")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(charity.shortName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
            
            VStack(spacing: 4) {
                Text("$\(String(format: "%.2f", stats.totalDonated))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("contributed")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}

struct MilestoneTemplateContent: View {
    let stats: DonationStats
    
    private var milestone: String {
        if stats.totalDonated >= 500 { return "Champion" }
        if stats.totalDonated >= 100 { return "Philanthropist" }
        if stats.totalDonated >= 50 { return "Generous Donor" }
        if stats.totalDonated >= 10 { return "Contributor" }
        return "Getting Started"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            
            Text(milestone)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("$\(String(format: "%.2f", stats.totalDonated)) donated")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
            
            Text("\(stats.longestStreak) day best streak")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

struct StatBubble: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.white.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Template Selector

struct TemplateSelectorView: View {
    @Binding var selectedTemplate: ShareTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Template")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShareTemplate.allCases) { template in
                        TemplateButton(
                            template: template,
                            isSelected: selectedTemplate == template
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTemplate = template
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TemplateButton: View {
    let template: ShareTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: template.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                Text(template.rawValue)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(8)
            .background(isSelected ? Color.orange.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Buttons Section

struct ShareButtonsSection: View {
    let onInstagram: () -> Void
    let onSnapchat: () -> Void
    let onMore: () -> Void
    let isGenerating: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Share to")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Instagram
                SocialButton(
                    icon: "camera.circle.fill",
                    label: "Instagram",
                    color: Color(red: 0.88, green: 0.19, blue: 0.42),
                    action: onInstagram,
                    isLoading: isGenerating
                )
                
                // Snapchat
                SocialButton(
                    icon: "message.circle.fill",
                    label: "Snapchat",
                    color: .yellow,
                    action: onSnapchat,
                    isLoading: isGenerating
                )
                
                // More
                SocialButton(
                    icon: "square.and.arrow.up.circle.fill",
                    label: "More",
                    color: .gray,
                    action: onMore,
                    isLoading: isGenerating
                )
            }
        }
        .padding(.horizontal)
    }
}

struct SocialButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 60, height: 60)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Info Section

struct InfoSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            
            Text("Share your impact and inspire others to wake up for a cause!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Image Content (for rendering)

struct ShareImageContent: View {
    let template: ShareTemplate
    let stats: DonationStats
    let charity: Charity
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: template.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 40) {
                // App branding
                HStack {
                    Image(systemName: "alarm.fill")
                    Text("Snooze If You Can")
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white.opacity(0.9))
                .font(.title2)
                
                Spacer()
                
                // Main content
                switch template {
                case .impact:
                    ImpactTemplateContent(stats: stats, charity: charity)
                case .streak:
                    StreakTemplateContent(stats: stats)
                case .donation:
                    DonationTemplateContent(stats: stats, charity: charity)
                case .milestone:
                    MilestoneTemplateContent(stats: stats)
                }
                
                Spacer()
                
                // CTA
                VStack(spacing: 12) {
                    Text("Download & make a difference!")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("Available on the App Store")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(60)
        }
    }
}

// MARK: - Preview

#Preview {
    SocialShareView()
        .environmentObject(AlarmManager())
        .environmentObject(CharityManager.shared)
}
