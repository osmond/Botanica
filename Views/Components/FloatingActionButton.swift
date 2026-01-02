//
//  FloatingActionButton.swift
//  Botanica
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(BotanicaTheme.Colors.primary)
                    .frame(width: BotanicaTheme.Sizing.fabSize, height: BotanicaTheme.Sizing.fabSize)
                    .shadow(
                        color: BotanicaTheme.Colors.primary.opacity(0.3),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Image(systemName: icon)
                    .font(.system(size: BotanicaTheme.Sizing.iconPrimary, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        } perform: {
            action()
            HapticManager.shared.medium()
        }
    }
}

struct FloatingActionButtonModifier: ViewModifier {
    let icon: String
    let action: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    FloatingActionButton(icon: icon, action: action)
                        .padding(.trailing, BotanicaTheme.Spacing.lg)
                        .padding(.bottom, BotanicaTheme.Spacing.xl)
                }
            }
        }
    }
}

extension View {
    func floatingActionButton(icon: String, action: @escaping () -> Void) -> some View {
        modifier(FloatingActionButtonModifier(icon: icon, action: action))
    }
}

#Preview {
    ZStack {
        BotanicaTheme.Colors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton(icon: "camera.viewfinder") {
                    print("Tapped!")
                }
                .padding()
            }
        }
    }
}
