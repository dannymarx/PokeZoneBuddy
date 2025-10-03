//
//  CachedAsyncImage.swift
//  PokeZoneBuddy
//
//  SwiftUI View für gecachte Async-Bilder
//  Version 0.2
//

import SwiftUI

/// SwiftUI View die Bilder asynchron lädt und cached
/// Verwendet ImageCacheService für optimale Performance
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    
    // MARK: - Properties
    
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: PlatformImage?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    // MARK: - Initializers
    
    /// Erstellt eine CachedAsyncImage mit Custom Content und Placeholder
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let image = loadedImage {
                #if os(macOS)
                content(Image(nsImage: image))
                #else
                content(Image(uiImage: image))
                #endif
            } else if isLoading {
                placeholder()
            } else if loadError != nil {
                // Error State
                placeholder()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        loadError = nil
        
        do {
            let image = try await ImageCacheService.shared.loadImage(from: url)
            loadedImage = image
        } catch {
            loadError = error
            print("⚠️ Fehler beim Laden von Bild: \(url.absoluteString) - \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

// MARK: - Convenience Initializer (Standard Placeholder)

extension CachedAsyncImage where Placeholder == AnyView {
    /// Erstellt eine CachedAsyncImage mit Standard-Placeholder
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.url = url
        self.content = content
        self.placeholder = {
            AnyView(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .controlSize(.small)
                    )
            )
        }
    }
}

// MARK: - Convenience Initializer (Simple Image)

extension CachedAsyncImage where Content == Image, Placeholder == AnyView {
    /// Erstellt eine Simple CachedAsyncImage die einfach das Bild zeigt
    init(url: URL?) {
        self.url = url
        self.content = { image in image }
        self.placeholder = {
            AnyView(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .controlSize(.small)
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Simple Image
        CachedAsyncImage(
            url: URL(string: "https://cdn.leekduck.com/assets/img/pokemon_icons/pokemon_icon_025_00.png")
        )
        .frame(width: 100, height: 100)
        
        // Custom Content
        CachedAsyncImage(
            url: URL(string: "https://cdn.leekduck.com/assets/img/pokemon_icons/pokemon_icon_025_00.png")
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
                .overlay(
                    ProgressView()
                )
        }
        .frame(width: 100, height: 100)
    }
    .padding()
}
