import Foundation
import Combine

final class BaustellenSpeicher: ObservableObject {
    @Published var baustellen: [Baustelle] = [] {
        didSet { speichern() }
    }

    private let key = "baupilot_baustellen_v62"

    init() {
        laden()
    }

    private func laden() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            baustellen = try JSONDecoder().decode([Baustelle].self, from: data)
        } catch {
            print("Fehler beim Laden: \(error.localizedDescription)")
        }
    }

    private func speichern() {
        do {
            let data = try JSONEncoder().encode(baustellen)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Fehler beim Speichern: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func addBaustelle(_ baustelle: Baustelle) -> LimitFehler? {
        guard baustellen.count < AppLimits.maxBaustellen else { return .maxBaustellen }
        baustellen.insert(baustelle, at: 0)
        return nil
    }

    func updateBaustelle(_ baustelle: Baustelle) {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelle.id }) else { return }
        baustellen[index] = baustelle
    }

    func deleteBaustelle(_ baustelle: Baustelle) {
        baustellen.removeAll { $0.id == baustelle.id }
    }

    @discardableResult
    func addEintrag(_ eintrag: BaustellenEintrag, to baustelleID: UUID) -> LimitFehler? {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return nil }
        guard baustellen[index].eintraege.count < AppLimits.maxEintraegeProBaustelle else { return .maxEintraegeProBaustelle }
        baustellen[index].eintraege.insert(eintrag, at: 0)
        return nil
    }

    func updateEintrag(_ eintrag: BaustellenEintrag, in baustelleID: UUID) {
        guard let baustellenIndex = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        guard let eintragIndex = baustellen[baustellenIndex].eintraege.firstIndex(where: { $0.id == eintrag.id }) else { return }
        baustellen[baustellenIndex].eintraege[eintragIndex] = eintrag
    }

    func deleteEintrag(_ eintrag: BaustellenEintrag, from baustelleID: UUID) {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        baustellen[index].eintraege.removeAll { $0.id == eintrag.id }
    }

    @discardableResult
    func addNachweis(_ nachweis: NachweisEintrag, to baustelleID: UUID) -> LimitFehler? {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return nil }
        guard baustellen[index].nachweise.count < AppLimits.maxNachweiseProBaustelle else { return .maxNachweiseProBaustelle }
        baustellen[index].nachweise.insert(nachweis, at: 0)
        return nil
    }

    func updateNachweis(_ nachweis: NachweisEintrag, in baustelleID: UUID) {
        guard let baustellenIndex = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        guard let index = baustellen[baustellenIndex].nachweise.firstIndex(where: { $0.id == nachweis.id }) else { return }
        baustellen[baustellenIndex].nachweise[index] = nachweis
    }

    func deleteNachweis(_ nachweis: NachweisEintrag, from baustelleID: UUID) {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        baustellen[index].nachweise.removeAll { $0.id == nachweis.id }
    }

    @discardableResult
    func addAufmass(_ aufmass: AufmassMaterialEintrag, to baustelleID: UUID) -> LimitFehler? {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return nil }
        guard baustellen[index].aufmasse.count < AppLimits.maxAufmasseProBaustelle else { return .maxAufmasseProBaustelle }
        baustellen[index].aufmasse.insert(aufmass, at: 0)
        return nil
    }

    func updateAufmass(_ aufmass: AufmassMaterialEintrag, in baustelleID: UUID) {
        guard let baustellenIndex = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        guard let index = baustellen[baustellenIndex].aufmasse.firstIndex(where: { $0.id == aufmass.id }) else { return }
        baustellen[baustellenIndex].aufmasse[index] = aufmass
    }

    func deleteAufmass(_ aufmass: AufmassMaterialEintrag, from baustelleID: UUID) {
        guard let index = baustellen.firstIndex(where: { $0.id == baustelleID }) else { return }
        baustellen[index].aufmasse.removeAll { $0.id == aufmass.id }
    }
}
