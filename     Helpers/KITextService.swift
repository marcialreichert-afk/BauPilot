//
//  KITextService.swift
//  BauPilot
//
//  Created by Marcial Reichert on 24.04.26.
//

import Foundation

enum KITextKontext: String, Codable {
    case eintrag
    case nachweis
    case aufmass
}

enum KITextServiceError: LocalizedError {
    case endpointNichtKonfiguriert
    case ungueltigeAntwort
    case serverFehler(String)

    var errorDescription: String? {
        switch self {
        case .endpointNichtKonfiguriert:
            return "ki.error.endpoint_not_configured".localized("KI-Service ist noch nicht konfiguriert.")
        case .ungueltigeAntwort:
            return "ki.error.invalid_response".localized("Die KI-Antwort konnte nicht verarbeitet werden.")
        case .serverFehler(let message):
            return message
        }
    }
}

struct KITextRequest: Encodable {
    let text: String
    let kontext: KITextKontext
}

struct KITextResponse: Decodable {
    let text: String?
    let improvedText: String?
    let result: String?
    let error: String?

    var finalText: String? {
        improvedText ?? text ?? result
    }
}

struct KIAufmassPositionResult: Decodable {
    let bezeichnung: String
    let menge: String
    let einheit: String
}

final class KITextService {
    static let shared = KITextService()

    private init() {}

    // Wichtig: Hier NICHT direkt einen OpenAI API-Key in die App packen.
    // Diese URL soll später auf deinen eigenen Backend-/Proxy-Endpunkt zeigen.
    private let endpoint = URL(string: "https://baupilot-ki-api.vercel.app/api/ki-text")

    func verbessereNotiz(_ text: String, kontext: KITextKontext) async throws -> String {
        guard let endpoint else {
            throw KITextServiceError.endpointNichtKonfiguriert
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceIDManager.shared.deviceID, forHTTPHeaderField: "X-BauPilot-Device-ID")
        request.timeoutInterval = 30

        let payload = KITextRequest(text: text, kontext: kontext)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            if httpResponse.statusCode == 403 {
                throw KITextServiceError.serverFehler("ki.text.pro_required".localized("KI ist nur in BauPilot Pro verfügbar."))
            }

            let message = String(data: data, encoding: .utf8) ?? "ki.error.service_failed".localized("KI-Service Fehler.")
            throw KITextServiceError.serverFehler(message)
        }

        let decoded = try JSONDecoder().decode(KITextResponse.self, from: data)

        if let error = decoded.error, !error.isEmpty {
            throw KITextServiceError.serverFehler(error)
        }

        guard let result = decoded.finalText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !result.isEmpty else {
            throw KITextServiceError.ungueltigeAntwort
        }

        return result
    }

    func parseAufmassPosition(_ text: String) async throws -> KIAufmassPositionResult {
        let prompt = """
        Extrahiere aus dem folgenden Rohtext genau eine Aufmaß-Position.

        Antworte ausschließlich als gültiges JSON ohne Markdown, ohne Erklärung und ohne zusätzlichen Text.

        JSON-Format:
        {
          "bezeichnung": "...",
          "menge": "...",
          "einheit": "..."
        }

        Regeln:
        - bezeichnung: kurze fachliche Bezeichnung der Position
        - menge: nur Zahl oder Mengenangabe als Text, z. B. "3", "12", "2,5"
        - einheit: passende Einheit, z. B. "Stk", "m", "m²", "m³", "kg", "l"
        - Wenn keine Einheit erkennbar ist, nutze "Stk"
        - Keine zusätzlichen Felder

        Rohtext:
        \(text)
        """

        let result = try await verbessereNotiz(prompt, kontext: .aufmass)
        let cleanedResult = result
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleanedResult.data(using: .utf8) else {
            throw KITextServiceError.ungueltigeAntwort
        }

        do {
            return try JSONDecoder().decode(KIAufmassPositionResult.self, from: data)
        } catch {
            throw KITextServiceError.ungueltigeAntwort
        }
    }
}
