import SwiftUI
import UIKit
import CoreText
import Foundation
import ImageIO

enum PDFExportHelper {
    static func exportPDF(for baustelle: Baustelle) -> URL? {
        let fileName = "BauPilot-\(safeFileName(baustelle.name.isEmpty ? "Baustelle" : baustelle.name))-\(UUID().uuidString).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 36

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        do {
            try renderer.writePDF(to: url) { context in
                var y: CGFloat = margin

                func newPageIfNeeded(_ neededHeight: CGFloat) {
                    if y + neededHeight > pageHeight - margin - 44 {
                        context.beginPage()
                        y = margin
                    }
                }

                func drawText(
                    _ text: String,
                    x: CGFloat,
                    y: CGFloat,
                    width: CGFloat,
                    attributes: [NSAttributedString.Key: Any]
                ) -> CGFloat {
                    let string = NSAttributedString(string: text, attributes: attributes)
                    let framesetter = CTFramesetterCreateWithAttributedString(string as CFAttributedString)
                    let size = CTFramesetterSuggestFrameSizeWithConstraints(
                        framesetter,
                        CFRange(),
                        nil,
                        CGSize(width: width, height: .greatestFiniteMagnitude),
                        nil
                    )
                    let rect = CGRect(x: x, y: y, width: width, height: ceil(size.height))
                    string.draw(in: rect)
                    return ceil(size.height)
                }

                func drawImageData(_ data: Data, x: CGFloat, y: CGFloat, maxSize: CGFloat) {
                    autoreleasepool {
                        guard let prepared = PDFExportHelper.preparedPDFImage(from: data) else { return }
                        let aspectRatio = prepared.size.width / max(prepared.size.height, 1)

                        let drawWidth: CGFloat
                        let drawHeight: CGFloat

                        if aspectRatio >= 1 {
                            drawWidth = maxSize
                            drawHeight = maxSize / max(aspectRatio, 0.01)
                        } else {
                            drawHeight = maxSize
                            drawWidth = maxSize * aspectRatio
                        }

                        prepared.draw(in: CGRect(x: x, y: y, width: drawWidth, height: drawHeight))
                    }
                }

                func centeredParagraphStyle() -> NSParagraphStyle {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    return style
                }

                func drawLine(x: CGFloat, y: CGFloat, width: CGFloat, color: UIColor, height: CGFloat = 1) {
                    color.setFill()
                    UIBezierPath(rect: CGRect(x: x, y: y, width: width, height: height)).fill()
                }

                func drawIconBadge(symbol: String, centerX: CGFloat, centerY: CGFloat) {
                    let badgeRect = CGRect(x: centerX - 18, y: centerY - 18, width: 36, height: 36)
                    UIColor(red: 0.88, green: 0.93, blue: 1.0, alpha: 1.0).setFill()
                    UIBezierPath(ovalIn: badgeRect).fill()

                    let iconRect = CGRect(x: centerX - 9, y: centerY - 9, width: 18, height: 18)
                    let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
                    if let image = UIImage(systemName: symbol, withConfiguration: config) {
                        image.withTintColor(UIColor(Color.bauPilotBlue), renderingMode: .alwaysOriginal).draw(in: iconRect)
                    }
                }

                func drawHeaderBrand(reportDate: String) {
                    let logoSize: CGFloat = 30
                    let logoX = pageWidth - margin - 132
                    let logoY = margin + 2
                    let logoRect = CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize)

                    UIColor(Color.bauPilotBlue).setFill()
                    UIBezierPath(roundedRect: logoRect, cornerRadius: 7).fill()

                    UIColor.white.setFill()
                    UIBezierPath(roundedRect: CGRect(x: logoRect.minX + 8, y: logoRect.minY + 8, width: 14, height: 2), cornerRadius: 1).fill()
                    UIBezierPath(roundedRect: CGRect(x: logoRect.minX + 8, y: logoRect.minY + 13, width: 14, height: 2), cornerRadius: 1).fill()
                    UIBezierPath(roundedRect: CGRect(x: logoRect.minX + 8, y: logoRect.minY + 18, width: 10, height: 2), cornerRadius: 1).fill()

                    _ = drawText(
                        "BauPilot",
                        x: logoRect.maxX + 8,
                        y: logoY + 2,
                        width: 90,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 20),
                            .foregroundColor: UIColor(Color.bauPilotBlue)
                        ]
                    )

                    let dateY = logoY + 52
                    let calendarRect = CGRect(x: logoX, y: dateY + 2, width: 16, height: 16)
                    let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
                    if let calendar = UIImage(systemName: "calendar", withConfiguration: config) {
                        calendar.withTintColor(UIColor(Color.bauPilotBlue), renderingMode: .alwaysOriginal).draw(in: calendarRect)
                    }

                    _ = drawText(
                        "pdf.field.report_created".localized("Bericht erstellt am"),
                        x: logoX + 22,
                        y: dateY,
                        width: 110,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 9),
                            .foregroundColor: UIColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0)
                        ]
                    )

                    _ = drawText(
                        reportDate,
                        x: logoX + 22,
                        y: dateY + 14,
                        width: 110,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 10),
                            .foregroundColor: UIColor(Color.bauPilotBlue)
                        ]
                    )
                }

                func drawProCoverPage(
                    reportDate: String,
                    siteName: String,
                    customerName: String,
                    locationName: String,
                    totalPhotos: Int,
                    totalProofs: Int
                ) {
                    let centerStyle = NSMutableParagraphStyle()
                    centerStyle.alignment = .center

                    let coverTitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 34),
                        .foregroundColor: UIColor(Color.bauPilotBlue),
                        .paragraphStyle: centerStyle
                    ]

                    let coverSubtitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 22),
                        .foregroundColor: UIColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0),
                        .paragraphStyle: centerStyle
                    ]

                    let coverTextAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 13),
                        .foregroundColor: UIColor(red: 0.25, green: 0.29, blue: 0.36, alpha: 1.0),
                        .paragraphStyle: centerStyle
                    ]

                    let logoRect = CGRect(x: pageWidth / 2 - 54, y: 82, width: 108, height: 108)
                    UIColor(Color.bauPilotBlue).setFill()
                    UIBezierPath(roundedRect: logoRect, cornerRadius: 24).fill()

                    let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold)
                    if let icon = UIImage(systemName: "doc.text.fill", withConfiguration: config) {
                        icon.withTintColor(.white, renderingMode: .alwaysOriginal)
                            .draw(in: CGRect(x: logoRect.midX - 27, y: logoRect.midY - 27, width: 54, height: 54))
                    }

                    _ = drawText(
                        "pdf.cover.pro.title".localized("BauPilot Pro"),
                        x: margin,
                        y: 220,
                        width: pageWidth - margin * 2,
                        attributes: coverTitleAttributes
                    )

                    _ = drawText(
                        "pdf.cover.report".localized("Professioneller Baustellenbericht"),
                        x: margin,
                        y: 266,
                        width: pageWidth - margin * 2,
                        attributes: coverSubtitleAttributes
                    )

                    _ = drawText(
                        siteName,
                        x: margin + 30,
                        y: 330,
                        width: pageWidth - margin * 2 - 60,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 25),
                            .foregroundColor: UIColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0),
                            .paragraphStyle: centerStyle
                        ]
                    )

                    let infoRect = CGRect(x: margin + 30, y: 418, width: pageWidth - margin * 2 - 60, height: 176)
                    UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0).setFill()
                    UIBezierPath(roundedRect: infoRect, cornerRadius: 18).fill()

                    let infoText = """
                    \("pdf.field.customer".localized("Kunde")): \(customerName)
                    \("pdf.field.location".localized("Ort")): \(locationName)
                    \("pdf.field.report_created".localized("Bericht erstellt")): \(reportDate)
                    \("pdf.section.proofs".localized("Nachweise")): \(totalProofs)
                    \("pdf.section.photos".localized("Fotos")): \(totalPhotos)
                    """

                    _ = drawText(
                        infoText,
                        x: infoRect.minX + 24,
                        y: infoRect.minY + 24,
                        width: infoRect.width - 48,
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 14),
                            .foregroundColor: UIColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1.0)
                        ]
                    )

                    _ = drawText(
                        "pdf.cover.footer".localized("Erstellt mit BauPilot Pro – schnelle Baustellendokumentation direkt vor Ort."),
                        x: margin + 50,
                        y: 700,
                        width: pageWidth - margin * 2 - 100,
                        attributes: coverTextAttributes
                    )
                }

                context.beginPage()

                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor(Color.bauPilotBlue)
                ]

                let headingAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0)
                ]

                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1.0)
                ]

                let smallAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor(red: 0.25, green: 0.29, blue: 0.36, alpha: 1.0)
                ]

                let reportDate = Date().formatted(date: .abbreviated, time: .shortened)
                let isProPDF = AppConfig.isProUser
                drawHeaderBrand(reportDate: reportDate)

                let siteName = baustelle.name.isEmpty ? "-" : baustelle.name
                let customerName = baustelle.kunde.isEmpty ? "-" : baustelle.kunde
                let locationName = baustelle.ort.isEmpty ? "-" : baustelle.ort
                let totalEntryPhotos = baustelle.eintraege.reduce(0) { $0 + $1.bilder.count }
                let totalProofPhotos = baustelle.nachweise.reduce(0) { $0 + $1.bilder.count }
                let totalMaterialPhotos = baustelle.aufmasse.filter { $0.bild != nil }.count
                let totalPhotos = totalEntryPhotos + totalProofPhotos + totalMaterialPhotos

                if isProPDF {
                    drawProCoverPage(
                        reportDate: reportDate,
                        siteName: siteName,
                        customerName: customerName,
                        locationName: locationName,
                        totalPhotos: totalPhotos,
                        totalProofs: baustelle.nachweise.count
                    )
                    context.beginPage()
                    y = margin
                    drawHeaderBrand(reportDate: reportDate)
                }

                let reportTitle = isProPDF
                    ? "pdf.title.pro".localized("BauPilot Pro – Baustellenbericht")
                    : "pdf.title".localized("BauPilot – Baustellenbericht")

                y += drawText(
                    reportTitle,
                    x: margin,
                    y: y,
                    width: pageWidth - margin * 2 - 150,
                    attributes: titleAttributes
                )
                y += 6

                y += drawText(
                    siteName,
                    x: margin,
                    y: y,
                    width: pageWidth - margin * 2,
                    attributes: [
                        .font: UIFont.boldSystemFont(ofSize: 24),
                        .foregroundColor: UIColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0)
                    ]
                )
                y += 16

                let headerRect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: 96)
                UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0).setFill()
                UIBezierPath(roundedRect: headerRect, cornerRadius: 12).fill()

                var headerY = y + 12
                let leftX = margin + 14
                let rightX = margin + (pageWidth - margin * 2) / 2 + 8
                let columnWidth = (pageWidth - margin * 2) / 2 - 22

                headerY += drawText(
                    "\("pdf.field.customer".localized("Kunde")): \(customerName)",
                    x: leftX,
                    y: headerY,
                    width: columnWidth,
                    attributes: textAttributes
                )
                headerY += 4
                headerY += drawText(
                    "\("pdf.field.location".localized("Ort")): \(locationName)",
                    x: leftX,
                    y: headerY,
                    width: columnWidth,
                    attributes: textAttributes
                )

                _ = drawText(
                    "\("pdf.field.created_at".localized("Baustelle erstellt")): \(baustelle.erstelltAm.formatted(date: .abbreviated, time: .omitted))\n\("pdf.field.report_created".localized("Bericht erstellt")): \(reportDate)",
                    x: rightX,
                    y: y + 12,
                    width: columnWidth,
                    attributes: textAttributes
                )

                y += headerRect.height + 18

                y += drawText(
                    "pdf.section.summary".localized("Zusammenfassung"),
                    x: margin,
                    y: y,
                    width: pageWidth - margin * 2,
                    attributes: headingAttributes
                )
                y += 8

                let summaryRect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: 138)
                UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0).setFill()
                UIBezierPath(roundedRect: summaryRect, cornerRadius: 14).fill()

                let summaryInnerX = summaryRect.minX + 16
                let summaryInnerWidth = summaryRect.width - 32
                let cardWidth = summaryInnerWidth / 4
                let iconY = summaryRect.minY + 34
                let numberY = summaryRect.minY + 62
                let labelY = summaryRect.minY + 92

                let summaryItems: [(String, String, String)] = [
                    ("pdf.section.entries".localized("Einträge"), "\(baustelle.eintraege.count)", "doc.text"),
                    ("pdf.section.proofs".localized("Nachweise"), "\(baustelle.nachweise.count)", "checkmark.shield"),
                    ("pdf.section.materials".localized("Aufmaß"), "\(baustelle.aufmasse.count)", "ruler"),
                    ("pdf.section.photos".localized("Fotos"), "\(totalPhotos)", "camera")
                ]

                for (index, item) in summaryItems.enumerated() {
                    let x = summaryInnerX + CGFloat(index) * cardWidth
                    let centerX = x + cardWidth / 2

                    if index > 0 {
                        drawLine(
                            x: x,
                            y: summaryRect.minY + 24,
                            width: 1,
                            color: UIColor(red: 0.78, green: 0.84, blue: 0.94, alpha: 1.0),
                            height: 88
                        )
                    }

                    drawIconBadge(symbol: item.2, centerX: centerX, centerY: iconY)

                    _ = drawText(
                        item.1,
                        x: x,
                        y: numberY,
                        width: cardWidth,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 24),
                            .foregroundColor: UIColor(Color.bauPilotBlue),
                            .paragraphStyle: centeredParagraphStyle()
                        ]
                    )

                    _ = drawText(
                        item.0,
                        x: x,
                        y: labelY,
                        width: cardWidth,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 10),
                            .foregroundColor: UIColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0),
                            .paragraphStyle: centeredParagraphStyle()
                        ]
                    )
                }

                y += summaryRect.height + 22

                if baustelle.eintraege.isEmpty && baustelle.nachweise.isEmpty && baustelle.aufmasse.isEmpty {
                    y += 42

                    let centerX = pageWidth / 2
                    let illustrationY = y
                    let cloudRect = CGRect(x: centerX - 74, y: illustrationY + 58, width: 148, height: 34)
                    UIColor(red: 0.91, green: 0.95, blue: 1.0, alpha: 1.0).setFill()
                    UIBezierPath(roundedRect: cloudRect, cornerRadius: 17).fill()

                    let boardRect = CGRect(x: centerX - 30, y: illustrationY + 18, width: 60, height: 78)
                    UIColor.white.setFill()
                    UIBezierPath(roundedRect: boardRect, cornerRadius: 7).fill()

                    UIColor(red: 0.62, green: 0.70, blue: 0.84, alpha: 1.0).setStroke()
                    let boardPath = UIBezierPath(roundedRect: boardRect, cornerRadius: 7)
                    boardPath.lineWidth = 3
                    boardPath.stroke()

                    UIColor(red: 0.56, green: 0.66, blue: 0.83, alpha: 1.0).setFill()
                    UIBezierPath(roundedRect: CGRect(x: centerX - 16, y: illustrationY + 8, width: 32, height: 17), cornerRadius: 5).fill()
                    UIBezierPath(ovalIn: CGRect(x: centerX - 5, y: illustrationY + 1, width: 10, height: 10)).fill()

                    UIColor(red: 0.84, green: 0.89, blue: 0.97, alpha: 1.0).setFill()
                    for index in 0..<4 {
                        UIBezierPath(
                            roundedRect: CGRect(
                                x: boardRect.minX + 16,
                                y: boardRect.minY + 20 + CGFloat(index) * 13,
                                width: 30,
                                height: 4
                            ),
                            cornerRadius: 2
                        ).fill()
                    }

                    y = illustrationY + 118

                    y += drawText(
                        "pdf.empty.title".localized("Noch keine Dokumentation vorhanden."),
                        x: margin,
                        y: y,
                        width: pageWidth - margin * 2,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 13),
                            .foregroundColor: UIColor(red: 0.05, green: 0.08, blue: 0.14, alpha: 1.0),
                            .paragraphStyle: centeredParagraphStyle()
                        ]
                    )

                    y += 6

                    y += drawText(
                        "pdf.empty.message".localized("Sobald Einträge, Nachweise, Aufmaße oder Fotos hinzugefügt werden, erscheinen sie hier im Bericht."),
                        x: margin + 70,
                        y: y,
                        width: pageWidth - margin * 2 - 140,
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 10),
                            .foregroundColor: UIColor(red: 0.36, green: 0.40, blue: 0.50, alpha: 1.0),
                            .paragraphStyle: centeredParagraphStyle()
                        ]
                    )

                    y += 30
                }

                if !baustelle.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    y += drawText("site.note".localized("Projekt-Notiz"), x: margin, y: y, width: pageWidth - margin * 2, attributes: headingAttributes)
                    y += 6
                    y += drawText(
                        SpeechTextFormatter.bullets(baustelle.notiz),
                        x: margin,
                        y: y,
                        width: pageWidth - margin * 2,
                        attributes: textAttributes
                    )
                    y += 16
                }

                if !baustelle.eintraege.isEmpty {
                    newPageIfNeeded(200)
                    y += drawText("pdf.section.entries".localized("Einträge"), x: margin, y: y, width: pageWidth - margin * 2, attributes: headingAttributes)
                    y += 10

                    for (index, eintrag) in baustelle.eintraege.enumerated() {
                        newPageIfNeeded(240)

                        let cardX = margin
                        let cardWidth = pageWidth - margin * 2
                        let cardStartY = y
                        let innerX = cardX + 14
                        let innerWidth = cardWidth - 28

                        UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0).setFill()
                        UIBezierPath(roundedRect: CGRect(x: cardX, y: cardStartY, width: cardWidth, height: 130), cornerRadius: 12).fill()

                        y = cardStartY + 12

                        y += drawText(
                            "\(index + 1). \(eintrag.titel.isEmpty ? "common.untitled".localized("Ohne Titel") : eintrag.titel)",
                            x: innerX,
                            y: y,
                            width: innerWidth,
                            attributes: headingAttributes
                        )
                        y += 6
                        drawLine(
                            x: innerX,
                            y: y,
                            width: innerWidth,
                            color: UIColor(red: 0.78, green: 0.84, blue: 0.94, alpha: 1.0),
                            height: 1
                        )
                        y += 8

                        let meta = """
                        \("pdf.field.category".localized("Kategorie")): \(eintrag.kategorie.localizedName)
                        \("pdf.field.date".localized("Datum")): \(eintrag.datum.formatted(date: .abbreviated, time: .shortened))
                        """

                        y += drawText(meta, x: innerX, y: y, width: innerWidth, attributes: smallAttributes)
                        y += 6

                        let badgeY = y
                        let badgeHeight: CGFloat = 16

                        func drawBadge(text: String, x: CGFloat, color: UIColor) -> CGFloat {
                            let padding: CGFloat = 6
                            let textWidth = text.size(withAttributes: [
                                .font: UIFont.boldSystemFont(ofSize: 9)
                            ]).width
                            let width = textWidth + padding * 2

                            color.withAlphaComponent(0.14).setFill()
                            UIBezierPath(
                                roundedRect: CGRect(x: x, y: badgeY, width: width, height: badgeHeight),
                                cornerRadius: 6
                            ).fill()

                            _ = drawText(
                                text,
                                x: x + padding,
                                y: badgeY + 2,
                                width: textWidth + 2,
                                attributes: [
                                    .font: UIFont.boldSystemFont(ofSize: 9),
                                    .foregroundColor: color
                                ]
                            )

                            return width + 6
                        }

                        var badgeX = innerX

                        let statusName = eintrag.status.localizedName
                        let statusLower = statusName.lowercased()
                        let statusColor: UIColor
                        if statusLower.contains("erledigt") || statusLower.contains("done") {
                            statusColor = .systemGreen
                        } else if statusLower.contains("bearbeitung") || statusLower.contains("progress") {
                            statusColor = .systemBlue
                        } else {
                            statusColor = .systemOrange
                        }

                        badgeX += drawBadge(text: statusName, x: badgeX, color: statusColor)

                        let priorityName = eintrag.prioritaet.localizedName
                        let priorityLower = priorityName.lowercased()
                        let priorityColor: UIColor
                        if priorityLower.contains("hoch") || priorityLower.contains("high") {
                            priorityColor = .systemRed
                        } else if priorityLower.contains("mittel") || priorityLower.contains("medium") {
                            priorityColor = .systemOrange
                        } else {
                            priorityColor = .systemBlue
                        }

                        _ = drawBadge(text: priorityName, x: badgeX, color: priorityColor)

                        y += badgeHeight + 10

                        if !eintrag.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            y += drawText(
                                SpeechTextFormatter.bullets(eintrag.notiz),
                                x: innerX,
                                y: y,
                                width: innerWidth,
                                attributes: textAttributes
                            )
                            y += 10
                        }

                        if y < cardStartY + 130 {
                            y = cardStartY + 130
                        }

                        if !eintrag.bilder.isEmpty {
                            y += 10

                            let spacing: CGFloat = isProPDF ? 12 : 10
                            let maxColumns = isProPDF ? 2 : 4
                            let imageSize: CGFloat = isProPDF
                                ? (pageWidth - margin * 2 - spacing) / 2
                                : 90

                            for (imgIndex, data) in eintrag.bilder.enumerated() {
                                let row = imgIndex / maxColumns
                                let col = imgIndex % maxColumns
                                let drawY = y + CGFloat(row) * (imageSize + spacing)
                                let drawX = margin + CGFloat(col) * (imageSize + spacing)

                                if drawY + imageSize > pageHeight - margin {
                                    context.beginPage()
                                    y = margin
                                }

                                if isProPDF {
                                    UIColor.white.setFill()
                                    UIBezierPath(
                                        roundedRect: CGRect(x: drawX - 4, y: drawY - 4, width: imageSize + 8, height: imageSize + 8),
                                        cornerRadius: 12
                                    ).fill()
                                }

                                drawImageData(data, x: drawX, y: drawY, maxSize: imageSize)
                            }

                            let rows = Int(ceil(Double(eintrag.bilder.count) / Double(maxColumns)))
                            y += CGFloat(rows) * (imageSize + spacing)
                        }

                        y += 18
                    }
                }

                if !baustelle.nachweise.isEmpty {
                    newPageIfNeeded(180)

                    let proofHeaderRect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: isProPDF ? 46 : 0)
                    if isProPDF {
                        UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1.0).setFill()
                        UIBezierPath(roundedRect: proofHeaderRect, cornerRadius: 14).fill()

                        let proofIconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
                        if let proofIcon = UIImage(systemName: "checkmark.shield.fill", withConfiguration: proofIconConfig) {
                            proofIcon.withTintColor(UIColor(Color.bauPilotBlue), renderingMode: .alwaysOriginal)
                                .draw(in: CGRect(x: margin + 14, y: y + 13, width: 20, height: 20))
                        }

                        _ = drawText(
                            "pdf.section.proofs".localized("Nachweise"),
                            x: margin + 42,
                            y: y + 13,
                            width: pageWidth - margin * 2 - 56,
                            attributes: [
                                .font: UIFont.boldSystemFont(ofSize: 16),
                                .foregroundColor: UIColor(Color.bauPilotBlue)
                            ]
                        )

                        y = proofHeaderRect.maxY + 12
                    } else {
                        y += drawText("pdf.section.proofs".localized("Nachweise"), x: margin, y: y, width: pageWidth - margin * 2, attributes: headingAttributes)
                        y += 10
                    }

                    for (index, nachweis) in baustelle.nachweise.enumerated() {
                        newPageIfNeeded(200)

                        let cardX = margin
                        let cardWidth = pageWidth - margin * 2
                        let cardStartY = y
                        let innerX = cardX + 14
                        let innerWidth = cardWidth - 28

                        if isProPDF {
                            UIColor(red: 0.94, green: 0.98, blue: 1.0, alpha: 1.0).setFill()
                            UIBezierPath(
                                roundedRect: CGRect(x: cardX, y: cardStartY, width: cardWidth, height: 126),
                                cornerRadius: 14
                            ).fill()

                            UIColor(Color.bauPilotBlue).setFill()
                            UIBezierPath(
                                roundedRect: CGRect(x: cardX, y: cardStartY, width: 5, height: 126),
                                cornerRadius: 2.5
                            ).fill()
                        } else {
                            UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0).setFill()
                            UIBezierPath(
                                roundedRect: CGRect(x: cardX, y: cardStartY, width: cardWidth, height: 118),
                                cornerRadius: 12
                            ).fill()
                        }

                        y = cardStartY + 12

                        y += drawText(
                            "\(index + 1). \(nachweis.titel.isEmpty ? "common.untitled".localized("Ohne Titel") : nachweis.titel)",
                            x: innerX,
                            y: y,
                            width: innerWidth,
                            attributes: isProPDF
                                ? [
                                    .font: UIFont.boldSystemFont(ofSize: 15),
                                    .foregroundColor: UIColor(Color.bauPilotBlue)
                                ]
                                : headingAttributes
                        )
                        y += 6
                        drawLine(
                            x: innerX,
                            y: y,
                            width: innerWidth,
                            color: UIColor(red: 0.78, green: 0.84, blue: 0.94, alpha: 1.0),
                            height: 1
                        )
                        y += 8

                        let meta = isProPDF
                            ? """
                            \("pdf.field.type".localized("Typ")): \(nachweis.typ.localizedName)
                            \("pdf.field.date".localized("Datum")): \(nachweis.datum.formatted(date: .abbreviated, time: .shortened))
                            \("pdf.field.attachments".localized("Anhänge")): \(nachweis.bilder.count)
                            """
                            : """
                            \("pdf.field.type".localized("Typ")): \(nachweis.typ.localizedName)
                            \("pdf.field.date".localized("Datum")): \(nachweis.datum.formatted(date: .abbreviated, time: .shortened))
                            """

                        y += drawText(meta, x: innerX, y: y, width: innerWidth, attributes: smallAttributes)
                        y += 8

                        if !nachweis.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            y += drawText(
                                SpeechTextFormatter.bullets(nachweis.notiz),
                                x: innerX,
                                y: y,
                                width: innerWidth,
                                attributes: textAttributes
                            )
                            y += 10
                        }

                        let proofCardMinHeight: CGFloat = isProPDF ? 126 : 118
                        if y < cardStartY + proofCardMinHeight {
                            y = cardStartY + proofCardMinHeight
                        }

                        if !nachweis.bilder.isEmpty {
                            y += 10

                            if isProPDF {
                                let attachmentHeaderRect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: 28)
                                UIColor(red: 0.97, green: 0.99, blue: 1.0, alpha: 1.0).setFill()
                                UIBezierPath(roundedRect: attachmentHeaderRect, cornerRadius: 10).fill()

                                _ = drawText(
                                    "pdf.proof.attachments".localized("Fotos / Unterschriften"),
                                    x: margin + 12,
                                    y: y + 7,
                                    width: pageWidth - margin * 2 - 24,
                                    attributes: [
                                        .font: UIFont.boldSystemFont(ofSize: 11),
                                        .foregroundColor: UIColor(Color.bauPilotBlue)
                                    ]
                                )
                                y += 38
                            }

                            let spacing: CGFloat = isProPDF ? 12 : 10
                            let maxColumns = isProPDF ? 2 : 4
                            let imageSize: CGFloat = isProPDF
                                ? (pageWidth - margin * 2 - spacing) / 2
                                : 110

                            for (imgIndex, data) in nachweis.bilder.enumerated() {
                                let row = imgIndex / maxColumns
                                let col = imgIndex % maxColumns
                                let drawY = y + CGFloat(row) * (imageSize + spacing)
                                let drawX = margin + CGFloat(col) * (imageSize + spacing)

                                if drawY + imageSize > pageHeight - margin {
                                    context.beginPage()
                                    y = margin
                                }

                                if isProPDF {
                                    UIColor.white.setFill()
                                    UIBezierPath(
                                        roundedRect: CGRect(x: drawX - 4, y: drawY - 4, width: imageSize + 8, height: imageSize + 8),
                                        cornerRadius: 12
                                    ).fill()
                                }

                                drawImageData(data, x: drawX, y: drawY, maxSize: imageSize)

                                if isProPDF {
                                    let labelText = "pdf.proof.attachment.label".localized("Nachweis-Anhang")
                                    let labelRect = CGRect(x: drawX, y: drawY + imageSize - 22, width: imageSize, height: 22)
                                    UIColor.black.withAlphaComponent(0.35).setFill()
                                    UIBezierPath(roundedRect: labelRect, cornerRadius: 7).fill()

                                    _ = drawText(
                                        labelText,
                                        x: drawX + 8,
                                        y: drawY + imageSize - 18,
                                        width: imageSize - 16,
                                        attributes: [
                                            .font: UIFont.boldSystemFont(ofSize: 9),
                                            .foregroundColor: UIColor.white,
                                            .paragraphStyle: centeredParagraphStyle()
                                        ]
                                    )
                                }
                            }

                            let rows = Int(ceil(Double(nachweis.bilder.count) / Double(maxColumns)))
                            y += CGFloat(rows) * (imageSize + spacing)
                        }

                        y += 18
                    }
                }

                if !baustelle.aufmasse.isEmpty {
                    newPageIfNeeded(170)
                    y += drawText("pdf.section.materials".localized("Aufmaß / Material"), x: margin, y: y, width: pageWidth - margin * 2, attributes: headingAttributes)
                    y += 10

                    for (index, aufmass) in baustelle.aufmasse.enumerated() {
                        newPageIfNeeded(120)

                        y += drawText(
                            "\(index + 1). \(aufmass.titel.isEmpty ? "material.empty.title".localized("Ohne Bezeichnung") : aufmass.titel)",
                            x: margin,
                            y: y,
                            width: pageWidth - margin * 2,
                            attributes: headingAttributes
                        )
                        y += 4

                        let meta = """
                        \("pdf.field.date".localized("Datum")): \(aufmass.datum.formatted(date: .abbreviated, time: .shortened))
                        \("pdf.field.quantity".localized("Menge")): \(aufmass.gesamtMengeAnzeige)
                        \("pdf.field.count".localized("Positionen")): \(aufmass.positionen.count)
                        """

                        y += drawText(meta, x: margin, y: y, width: pageWidth - margin * 2, attributes: smallAttributes)
                        y += 8

                        if !aufmass.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            y += drawText(
                                SpeechTextFormatter.bullets(aufmass.notiz),
                                x: margin,
                                y: y,
                                width: pageWidth - margin * 2,
                                attributes: textAttributes
                            )
                            y += 8
                        }

                        if !aufmass.positionen.isEmpty {
                            for position in aufmass.positionen {
                                newPageIfNeeded(60)

                                let mengeText = "\(position.menge) \(position.einheit)".trimmingCharacters(in: .whitespaces)
                                let posText = """
                                • \(position.bezeichnung.isEmpty ? "-" : position.bezeichnung)
                                  \("pdf.field.quantity".localized("Menge")): \(mengeText.isEmpty ? "-" : mengeText)
                                  \("pdf.field.area".localized("Bereich")): \(position.bereich.isEmpty ? "-" : position.bereich)
                                """

                                y += drawText(
                                    posText,
                                    x: margin + 8,
                                    y: y,
                                    width: pageWidth - margin * 2 - 8,
                                    attributes: textAttributes
                                )
                                y += 6

                                if !position.notiz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    y += drawText(
                                        SpeechTextFormatter.bullets(position.notiz),
                                        x: margin + 18,
                                        y: y,
                                        width: pageWidth - margin * 2 - 18,
                                        attributes: smallAttributes
                                    )
                                    y += 6
                                }
                            }
                        }

                        if let data = aufmass.bild {
                            let size: CGFloat = 110
                            newPageIfNeeded(size + 10)
                            drawImageData(data, x: margin, y: y, maxSize: size)
                            y += size + 12
                        }

                        y += 12
                    }
                }
                let footerY = pageHeight - margin + 10

                let footerText = isProPDF
                    ? "pdf.footer.pro".localized("Erstellt mit BauPilot Pro")
                    : "pdf.footer.created_with".localized("Erstellt mit BauPilot")

                _ = drawText(
                    footerText,
                    x: margin,
                    y: footerY,
                    width: 200,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.gray
                    ]
                )

                if !isProPDF {
                    let watermark = "BauPilot"
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 80),
                        .foregroundColor: UIColor.lightGray.withAlphaComponent(0.1)
                    ]

                    let size = watermark.size(withAttributes: attributes)
                    let rect = CGRect(
                        x: (pageWidth - size.width) / 2,
                        y: (pageHeight - size.height) / 2,
                        width: size.width,
                        height: size.height
                    )

                    watermark.draw(in: rect, withAttributes: attributes)
                }

                _ = drawText(
                    "\("pdf.footer.page".localized("Seite")) 1",
                    x: pageWidth - margin - 100,
                    y: footerY,
                    width: 100,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 10),
                        .foregroundColor: UIColor.gray
                    ]
                )
            }

            return url
        } catch {
            print("PDF Fehler: \(error.localizedDescription)")
            return nil
        }
    }

    private static func preparedPDFImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: 1000
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
    }

    private static func safeFileName(_ text: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return text.components(separatedBy: invalid).joined(separator: "-")
    }
}
