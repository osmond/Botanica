//
//  AboutView.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

/// About screen showing app information, version, and credits
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    private let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Botanica"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: BotanicaTheme.Spacing.xl) {
                    // App Header
                    appHeaderSection
                    
                    // Description
                    descriptionSection
                    
                    // Features
                    featuresSection
                    
                    // Credits
                    creditsSection
                    
                    // Version Info
                    versionSection
                }
                .padding(BotanicaTheme.Spacing.lg)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - App Header Section
    
    private var appHeaderSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.lg) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                BotanicaTheme.Colors.leafGreen,
                                BotanicaTheme.Colors.forestGreen
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: BotanicaTheme.Colors.leafGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                Text(appName)
                    .font(BotanicaTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your AI-Powered Plant Care Companion")
                    .font(BotanicaTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("About Botanica")
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(.primary)
            
            Text("""
            Botanica is designed to help you become the best plant parent you can be. With AI-powered plant identification, personalized care recommendations, and comprehensive tracking tools, keeping your plants healthy has never been easier.
            
            Whether you're a beginner learning the basics or an experienced gardener looking to optimize your care routine, Botanica provides the insights and reminders you need to help your plants thrive.
            """)
                .font(BotanicaTheme.Typography.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(BotanicaTheme.Spacing.lg)
        .background(BotanicaTheme.Colors.surface)
        .cornerRadius(BotanicaTheme.CornerRadius.medium)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Key Features")
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BotanicaTheme.Spacing.md) {
                FeatureCard(
                    icon: "camera.viewfinder",
                    title: "AI Plant ID",
                    description: "Instantly identify plants with your camera",
                    color: BotanicaTheme.Colors.primary
                )
                
                FeatureCard(
                    icon: "brain.head.profile.fill",
                    title: "Smart Care",
                    description: "Personalized care recommendations",
                    color: BotanicaTheme.Colors.leafGreen
                )
                
                FeatureCard(
                    icon: "calendar.badge.clock",
                    title: "Care Tracking",
                    description: "Never miss watering or fertilizing",
                    color: BotanicaTheme.Colors.waterBlue
                )
                
                FeatureCard(
                    icon: "lightbulb.fill",
                    title: "Care Insights",
                    description: "Gentle patterns from your care logs",
                    color: BotanicaTheme.Colors.nutrientOrange
                )
                
                FeatureCard(
                    icon: "photo.on.rectangle",
                    title: "Photo Journal",
                    description: "Document your plants' growth",
                    color: BotanicaTheme.Colors.terracotta
                )
                
                FeatureCard(
                    icon: "bell.fill",
                    title: "Smart Reminders",
                    description: "Timely care notifications",
                    color: BotanicaTheme.Colors.soilBrown
                )
            }
        }
    }
    
    // MARK: - Credits Section
    
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: BotanicaTheme.Spacing.md) {
            Text("Powered By")
                .font(BotanicaTheme.Typography.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: BotanicaTheme.Spacing.sm) {
                CreditRow(
                    title: "OpenAI GPT-4",
                    description: "AI plant identification and care recommendations"
                )
                
                CreditRow(
                    title: "SwiftUI & SwiftData",
                    description: "Modern iOS development framework"
                )
                
                CreditRow(
                    title: "SF Symbols",
                    description: "Beautiful system iconography"
                )
            }
            .padding(BotanicaTheme.Spacing.md)
            .background(BotanicaTheme.Colors.surface)
            .cornerRadius(BotanicaTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Version Section
    
    private var versionSection: some View {
        VStack(spacing: BotanicaTheme.Spacing.sm) {
            Text("Version \\(appVersion) (\\(buildNumber))")
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
            
            Text("© 2024 Botanica. Made for plant lovers.")
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: BotanicaTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(BotanicaTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(BotanicaTheme.Typography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(BotanicaTheme.Spacing.md)
        .background(BotanicaTheme.Colors.surface)
        .cornerRadius(BotanicaTheme.CornerRadius.medium)
    }
}

// MARK: - Credit Row

struct CreditRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BotanicaTheme.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(description)
                .font(BotanicaTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AboutView()
}
