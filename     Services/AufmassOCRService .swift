import Foundation
import UIKit
import Vision

struct OCRAufmassVorschlag: Identifiable, Codable, Equatable {
    let id: UUID
    var originalZeile: String
    var bezeichnung: String
    var menge: String
    var einheit: String
    var bereich: String
    var istUnsicher: Bool
    var warnhinweis: String?

    init(
        id: UUID = UUID(),
        originalZeile: String = "",
        bezeichnung: String = "",
        menge: String = "",
        einheit: String = "Stk",
        bereich: String = "",
        istUnsicher: Bool = false,
        warnhinweis: String? = nil
    ) {
        self.id = id
        self.originalZeile = originalZeile
        self.bezeichnung = bezeichnung
        self.menge = menge
        self.einheit = einheit
        self.bereich = bereich
        self.istUnsicher = istUnsicher
        self.warnhinweis = warnhinweis
    }
}

enum AufmassOCRError: LocalizedError {
    case imageConversionFailed
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "material.ocr.error.image_conversion_failed".localized("Das Bild konnte nicht für OCR verarbeitet werden.")
        case .noTextFound:
            return "material.ocr.error.no_text_found".localized("Es konnte kein brauchbarer Text erkannt werden.")
        }
    }
}

enum AufmassOCRService {
    static func erkennePositionen(
        aus image: UIImage,
        completion: @escaping (Result<[OCRAufmassVorschlag], Error>) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(.failure(AufmassOCRError.imageConversionFailed))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let zeilen = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .map { cleanLine($0) }
                .filter { !$0.isEmpty }

            let vorschlaege = parseSuggestions(from: zeilen)

            DispatchQueue.main.async {
                if vorschlaege.isEmpty {
                    completion(.failure(AufmassOCRError.noTextFound))
                } else {
                    completion(.success(vorschlaege))
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["de-DE", "en-US"]

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private static func cleanLine(_ line: String) -> String {
        line
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseSuggestions(from lines: [String]) -> [OCRAufmassVorschlag] {
        lines.compactMap { line in
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard cleaned.count >= 2 else { return nil }

            let tokens = cleaned
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            if tokens.isEmpty { return nil }

            var menge = ""
            var einheit = "Stk"
            var bereich = ""
            var usedIndexes = Set<Int>()

            if let qtyIndex = tokens.firstIndex(where: { looksLikeQuantity($0) }) {
                menge = normalizedQuantity(tokens[qtyIndex])
                usedIndexes.insert(qtyIndex)

                let nextIndex = qtyIndex + 1
                if nextIndex < tokens.count, looksLikeUnit(tokens[nextIndex]) {
                    einheit = normalizedUnit(tokens[nextIndex])
                    usedIndexes.insert(nextIndex)
                }
            }

            if let areaIndex = tokens.firstIndex(where: { looksLikeAreaToken($0) }) {
                bereich = normalizedArea(tokens[areaIndex])
                usedIndexes.insert(areaIndex)
            }

            let bezeichnungTokens = tokens.enumerated()
                .filter { !usedIndexes.contains($0.offset) }
                .map(\.element)

            let bezeichnung = bezeichnungTokens
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let finalBezeichnung = bezeichnung.isEmpty ? cleaned : bezeichnung
            let warnhinweise = warningHints(
                originalLine: cleaned,
                bezeichnung: finalBezeichnung,
                menge: menge,
                tokens: tokens
            )

            return OCRAufmassVorschlag(
                originalZeile: cleaned,
                bezeichnung: finalBezeichnung,
                menge: menge,
                einheit: einheit,
                bereich: bereich,
                istUnsicher: !warnhinweise.isEmpty,
                warnhinweis: warnhinweise.joined(separator: " · ")
            )
        }
    }

    private static func warningHints(
        originalLine: String,
        bezeichnung: String,
        menge: String,
        tokens: [String]
    ) -> [String] {
        var hints: [String] = []

        if menge.isEmpty {
            hints.append("material.ocr.hint.no_quantity".localized("Keine eindeutige Menge erkannt"))
        }

        if bezeichnung.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
            hints.append("material.ocr.hint.incomplete_description".localized("Bezeichnung wirkt unvollständig"))
        }

        if originalLine.contains("?") || originalLine.contains("�") {
            hints.append("material.ocr.hint.unclear_characters".localized("Unklare Zeichen erkannt"))
        }

        if containsStrongOCRNoise(originalLine) {
            hints.append("material.ocr.hint.hard_to_read".localized("Zeile wirkt schwer lesbar"))
        }

        if tokens.count == 1 && menge.isEmpty {
            hints.append("material.ocr.hint.single_uncertain_value".localized("Nur ein einzelner unsicherer Wert erkannt"))
        }

        if looksLikeMixedArticleCode(bezeichnung) && bezeichnung.count < 5 {
            hints.append("material.ocr.hint.incomplete_article_text".localized("Artikeltext wirkt unvollständig"))
        }

        return Array(Set(hints))
    }

    private static func containsStrongOCRNoise(_ text: String) -> Bool {
        let suspiciousCharacters = CharacterSet(charactersIn: "[]{}|_=~<>;“”‘’")
        if text.rangeOfCharacter(from: suspiciousCharacters) != nil {
            return true
        }

        let compact = text.replacingOccurrences(of: " ", with: "")
        let nonAlphaNumericCount = compact.unicodeScalars.filter {
            !CharacterSet.alphanumerics.contains($0) && $0 != "," && $0 != "." && $0 != "-" && $0 != "/"
        }.count

        return nonAlphaNumericCount >= 2
    }

    private static func looksLikeMixedArticleCode(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")
        let hasLetter = compact.rangeOfCharacter(from: .letters) != nil
        let hasDigit = compact.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasDigit
    }

    private static func looksLikeQuantity(_ token: String) -> Bool {
        let cleaned = token
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "x", with: "")
        return Double(cleaned) != nil
    }

    private static func normalizedQuantity(_ token: String) -> String {
        token.replacingOccurrences(of: ".", with: ",")
    }

    private static func looksLikeUnit(_ token: String) -> Bool {
        let t = token.lowercased()
        let units = [
            "stk", "st", "m", "lfm", "m2", "m²", "m3", "m³",
            "kg", "g", "l", "ml", "qm", "paar", "satz"
        ]
        return units.contains(t)
    }

    private static func normalizedUnit(_ token: String) -> String {
        switch token.lowercased() {
        case "st":
            return "Stk"
        case "m²", "qm":
            return "m²"
        case "m³":
            return "m³"
        default:
            return token
        }
    }

    private static func looksLikeAreaToken(_ token: String) -> Bool {
        let lower = token.lowercased()
        let prefixes = ["og", "eg", "kg", "dg", "bad", "wc", "küche", "kueche", "zimmer", "flur", "büro", "buero"]
        return prefixes.contains(where: { lower.contains($0) })
    }

    private static func normalizedArea(_ token: String) -> String {
        token.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
