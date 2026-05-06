import Foundation

enum LimitFehler: LocalizedError, Identifiable {
    case maxBaustellen
    case maxEintraegeProBaustelle
    case maxFotosProEintrag
    case maxNachweiseProBaustelle
    case maxAufmasseProBaustelle
    case maxFotosProAufmass

    var id: String {
        switch self {
        case .maxBaustellen: return "maxBaustellen"
        case .maxEintraegeProBaustelle: return "maxEintraegeProBaustelle"
        case .maxFotosProEintrag: return "maxFotosProEintrag"
        case .maxNachweiseProBaustelle: return "maxNachweiseProBaustelle"
        case .maxAufmasseProBaustelle: return "maxAufmasseProBaustelle"
        case .maxFotosProAufmass: return "maxFotosProAufmass"
        }
    }

    var errorDescription: String? {
        switch self {
        case .maxBaustellen:
            return AppConfig.isProUser
            ? "limit.sites.pro".localized("Unbegrenzte Baustellen möglich.")
            : "limit.sites.free".localized("In der kostenlosen Version sind maximal \(AppLimits.maxBaustellen) Baustellen möglich. Mit BauPilot Pro kannst du unbegrenzt Baustellen erstellen.")
        case .maxEintraegeProBaustelle:
            return AppConfig.isProUser
            ? "limit.entries.pro".localized("Unbegrenzte Einträge möglich.")
            : "limit.entries.free".localized("In der kostenlosen Version sind maximal \(AppLimits.maxEintraegeProBaustelle) Einträge pro Baustelle möglich. Mit BauPilot Pro kannst du unbegrenzt Einträge hinzufügen.")
        case .maxFotosProEintrag:
            return AppConfig.isProUser
            ? "limit.entry_photos.pro".localized("Unbegrenzte Fotos möglich.")
            : "limit.entry_photos.free".localized("In der kostenlosen Version sind maximal \(AppLimits.maxFotosProEintrag) Fotos pro Eintrag möglich. Mit BauPilot Pro kannst du unbegrenzt Fotos hinzufügen.")
        case .maxNachweiseProBaustelle:
            return AppConfig.isProUser
            ? "limit.proofs.pro".localized("Unbegrenzte Nachweise möglich.")
            : "limit.proofs.free".localized("In der kostenlosen Version sind maximal \(AppLimits.maxNachweiseProBaustelle) Nachweise möglich. Mit BauPilot Pro kannst du unbegrenzt Nachweise hinzufügen.")
        case .maxAufmasseProBaustelle:
            return AppConfig.isProUser
            ? "limit.materials.pro".localized("Unbegrenztes Aufmaß möglich.")
            : "limit.materials.free".localized("In der kostenlosen Version ist maximal \(AppLimits.maxAufmasseProBaustelle) Aufmaß möglich. Mit BauPilot Pro kannst du unbegrenzt Aufmaß erstellen.")
        case .maxFotosProAufmass:
            return AppConfig.isProUser
            ? "limit.material_photo.pro".localized("Unbegrenzte Fotos möglich.")
            : "limit.material_photo.free".localized("In der kostenlosen Version ist maximal \(AppLimits.maxFotosProAufmass) Foto möglich. Mit BauPilot Pro kannst du unbegrenzt Fotos hinzufügen.")
        }
    }
}
