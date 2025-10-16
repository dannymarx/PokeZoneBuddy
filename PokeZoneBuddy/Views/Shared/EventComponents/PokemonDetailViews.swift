//
//  PokemonDetailViews.swift
//  PokeZoneBuddy
//
//  Components für Pokemon-Anzeige in Events
//  Version 0.2
//

import SwiftUI

// MARK: - Spotlight Hour Details

/// Zeigt Details für Spotlight Hour Events
struct SpotlightHourDetailView: View {
    let details: SpotlightDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.yellow)
                Text(String(localized: "spotlight_hour"))
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            
            // Featured Pokemon
            HStack(spacing: 16) {
                // Pokemon Image
                AsyncImage(url: URL(string: details.featuredPokemonImage)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .overlay(
                                ProgressView()
                                    .controlSize(.small)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                    }
                }
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                
                // Pokemon Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(details.featuredPokemonName)
                            .font(.system(size: 20, weight: .bold))
                        
                        if details.canBeShiny {
                            ShinyBadge()
                        }
                    }
                    
                    // Bonus
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                        Text(details.bonus)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.1))
                    )
                }
                
                Spacer()
            }
            
            // All Featured Pokemon (if multiple)
            if details.allFeaturedPokemon.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "all_featured_pokemon"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(details.allFeaturedPokemon, id: \.name) { pokemon in
                                PokemonIconView(pokemon: pokemon, size: 60)
                            }
                        }
                    }
                    .scrollIndicators(.hidden, axes: .horizontal)
                    .hideScrollIndicatorsCompat()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .yellow.opacity(0.3),
                            .orange.opacity(0.2),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .yellow.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Raid Battle Details

/// Zeigt Details für Raid Battle Events
struct RaidBattleDetailView: View {
    let details: RaidDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.red)
                Text(String(localized: "raid_bosses"))
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            
            // Boss List
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(details.bosses, id: \.name) { boss in
                        RaidBossCard(pokemon: boss)
                    }
                }
            }
            .scrollIndicators(.hidden, axes: .horizontal)
            .hideScrollIndicatorsCompat()
            
            // Available Shinies
            if !details.availableShinies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "available_shinies"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(details.availableShinies, id: \.name) { shiny in
                                PokemonIconView(pokemon: shiny, size: 60, showShinyBadge: true)
                            }
                        }
                    }
                    .scrollIndicators(.hidden, axes: .horizontal)
                    .hideScrollIndicatorsCompat()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .red.opacity(0.3),
                            .orange.opacity(0.2),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .red.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Community Day Details

/// Zeigt Details für Community Day Events
struct CommunityDayDetailView: View {
    let details: CommunityDayDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.green)
                Text(String(localized: "community_day"))
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            
            // Featured Pokemon
            if !details.featuredPokemon.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "featured_pokemon"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(details.featuredPokemon, id: \.name) { pokemon in
                                PokemonIconView(pokemon: pokemon, size: 80)
                            }
                        }
                    }
                    .scrollIndicators(.hidden, axes: .horizontal)
                    .hideScrollIndicatorsCompat()
                }
            }
            
            // Shinies
            if !details.shinies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text(String(localized: "shiny_pokemon"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        ShinyBadge()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(details.shinies, id: \.name) { shiny in
                                PokemonIconView(pokemon: shiny, size: 60, showShinyBadge: false)
                            }
                        }
                    }
                    .scrollIndicators(.hidden, axes: .horizontal)
                    .hideScrollIndicatorsCompat()
                }
            }
            
            // Bonuses
            if !details.bonuses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "bonuses"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 8) {
                        ForEach(details.bonuses, id: \.text) { bonus in
                            BonusRowView(bonus: bonus)
                        }
                    }
                }
            }
            
            // Special Research
            if details.hasSpecialResearch {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.purple)
                    Text(String(localized: "special_research_available"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.purple.opacity(0.1))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .green.opacity(0.3),
                            .blue.opacity(0.2),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .green.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Supporting Views

/// Pokemon Icon mit Namen und Shiny-Badge
struct PokemonIconView: View {
    let pokemon: PokemonInfo
    let size: CGFloat
    var showShinyBadge: Bool = true
    
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: pokemon.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.quaternary)
                        .overlay(
                            ProgressView()
                                .controlSize(.small)
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.quaternary)
                }
            }
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
            )
            
            VStack(spacing: 2) {
                Text(pokemon.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                
                if pokemon.canBeShiny && showShinyBadge {
                    ShinyBadge(compact: true)
                }
            }
        }
        .frame(width: size + 20)
    }
}

/// Raid Boss Card mit größerer Darstellung
struct RaidBossCard: View {
    let pokemon: PokemonInfo
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: pokemon.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary)
                        .overlay(
                            ProgressView()
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary)
                }
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.red.opacity(0.1))
            )
            
            VStack(spacing: 4) {
                Text(pokemon.name)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                if pokemon.canBeShiny {
                    ShinyBadge()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .frame(width: 140)
    }
}

/// Shiny Badge Component
struct ShinyBadge: View {
    var compact: Bool = false
    
    var body: some View {
        HStack(spacing: compact ? 2 : 4) {
            Image(systemName: "sparkles")
                .font(.system(size: compact ? 8 : 10, weight: .bold))
            if !compact {
                Text(String(localized: "shiny_label"))
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, compact ? 2 : 3)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.yellow, .orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .foregroundStyle(.white)
    }
}

/// Bonus Row für Community Day
struct BonusRowView: View {
    let bonus: CommunityDayBonus
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let iconURL = bonus.iconURL, let url = URL(string: iconURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure, .empty:
                        Circle()
                            .fill(.quaternary)
                    @unknown default:
                        Circle()
                            .fill(.quaternary)
                    }
                }
                .frame(width: 28, height: 28)
            } else {
                Image(systemName: "gift.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                    .frame(width: 28, height: 28)
            }
            
            // Text
            Text(bonus.text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Previews

#Preview("Spotlight Hour") {
    ScrollView {
        SpotlightHourDetailView(
            details: SpotlightDetails(
                featuredPokemonName: "Pikachu",
                featuredPokemonImage: "https://cdn.leekduck.com/assets/img/pokemon_icons/pokemon_icon_025_00.png",
                canBeShiny: true,
                bonus: "2× Catch Stardust",
                allFeaturedPokemon: [
                    PokemonInfo(
                        name: "Pikachu",
                        imageURL: "https://cdn.leekduck.com/assets/img/pokemon_icons/pokemon_icon_025_00.png",
                        canBeShiny: true
                    )
                ]
            )
        )
        .padding()
    }
    .scrollIndicators(.hidden, axes: .vertical)
    .hideScrollIndicatorsCompat()
}

#Preview("Raid Battles") {
    ScrollView {
        RaidBattleDetailView(
            details: RaidDetails(
                bosses: [
                    PokemonInfo(
                        name: "Lugia",
                        imageURL: "https://cdn.leekduck.com/assets/img/pokemon_icons/pokemon_icon_249_00.png",
                        canBeShiny: true
                    ),
                    PokemonInfo(
                        name: "Ho-Oh",
                        imageURL: "https://cdn.leekduck.com/assets/img/pokemon_icons/pokemon_icon_250_00.png",
                        canBeShiny: true
                    )
                ],
                availableShinies: [
                    PokemonInfo(
                        name: "Lugia",
                        imageURL: "https://cdn.leekduck.com/assets/img/pokemon_icons/pokemon_icon_249_00_shiny.png",
                        canBeShiny: true
                    )
                ]
            )
        )
        .padding()
    }
    .scrollIndicators(.hidden, axes: .vertical)
    .hideScrollIndicatorsCompat()
}
