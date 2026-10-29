//
//  ScreenshotSampleData.swift
//  Little Artist
//
//  DEBUG-only sample library used to capture App Store screenshots with a
//  gallery full of colourful, child-style artwork (drawn procedurally, so
//  there are no real children's images or copyright concerns).
//
//  Enable with the launch arguments: -uiTesting -uiTestSeedSampleArtwork
//

#if DEBUG
import SwiftData
import UIKit

enum ScreenshotSampleData {

    /// Inserts two artists and a year of artwork into `context`.
    static func seed(into context: ModelContext) {
        let mia = Child(name: "Mia", avatarColor: "F2784B", createdAt: date(monthsAgo: 26))
        let leo = Child(name: "Leo", avatarColor: "7EB8DA", createdAt: date(monthsAgo: 20))
        context.insert(mia)
        context.insert(leo)

        let pieces: [(Child, String, String, Subject, Int, Bool)] = [
            (mia, "Sunny Day at the Park", "Mia drew everyone on the swings — even the dog!", .sunnyHouse, 0, true),
            (leo, "Rainbow Rocket", "Leo says it flies to the moon on Saturdays.", .rocket, 0, false),
            (mia, "Our Family", "Mum, Dad, Leo, me and Biscuit the cat.", .family, 1, true),
            (leo, "Big Red Truck", "Vroom vroom! First drawing with wheels.", .truck, 2, false),
            (mia, "Under the Sea", "A shy octopus hiding from the fish.", .ocean, 3, false),
            (leo, "Dinosaur Garden", "A friendly dinosaur who eats flowers.", .dinosaur, 4, true),
            (mia, "Butterfly Dance", "Painted with fingers at nursery.", .butterfly, 6, false),
            (leo, "Night Sky", "Leo counted 20 stars.", .nightSky, 8, false),
            (mia, "Rainbow Over Grandma's", "For Grandma's birthday card.", .rainbow, 12, true),
            (leo, "First Scribble Sun", "His very first sun!", .sunnyHouse, 12, false),
            (mia, "Flower Pot", "Three tulips and a bee.", .flowers, 14, false),
            (mia, "Snowman", "He has a carrot nose and a stripy scarf.", .snowman, 18, false),
        ]

        for (index, piece) in pieces.enumerated() {
            let image = draw(piece.3, seed: index)
            let artwork = Artwork(
                title: piece.1,
                caption: piece.2,
                imageData: image.jpegData(compressionQuality: 0.85),
                thumbnailData: image.preparingThumbnail(of: CGSize(width: 400, height: 400))?.jpegData(compressionQuality: 0.8),
                isFavorited: piece.5,
                // An exact anniversary, so "On This Day" shows in screenshots.
                createdAt: piece.4 == 12 && index == 8 ? date(yearsAgo: 1) : date(monthsAgo: piece.4, dayOffset: index),
                child: piece.0
            )
            context.insert(artwork)
        }
        try? context.save()
    }

    // MARK: - Dates

    private static func date(monthsAgo: Int, dayOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .month, value: -monthsAgo, to: .now) ?? .now
        return calendar.date(byAdding: .day, value: -(dayOffset % 5) - (monthsAgo == 0 ? 1 : 0), to: base) ?? base
    }

    private static func date(yearsAgo: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: -yearsAgo, to: .now) ?? .now
    }

    // MARK: - Drawing

    enum Subject {
        case sunnyHouse, rocket, family, truck, ocean, dinosaur, butterfly, nightSky, rainbow, flowers, snowman
    }

    private static let palette: [UIColor] = [
        UIColor(red: 0.95, green: 0.33, blue: 0.27, alpha: 1), // red
        UIColor(red: 0.98, green: 0.62, blue: 0.20, alpha: 1), // orange
        UIColor(red: 0.99, green: 0.84, blue: 0.22, alpha: 1), // yellow
        UIColor(red: 0.36, green: 0.73, blue: 0.36, alpha: 1), // green
        UIColor(red: 0.27, green: 0.55, blue: 0.90, alpha: 1), // blue
        UIColor(red: 0.58, green: 0.40, blue: 0.80, alpha: 1), // purple
        UIColor(red: 0.95, green: 0.50, blue: 0.70, alpha: 1), // pink
    ]

    private static func color(_ index: Int) -> UIColor { palette[index % palette.count] }

    /// Draws a crayon-style picture on slightly off-white paper.
    static func draw(_ subject: Subject, seed: Int) -> UIImage {
        let size = CGSize(width: 1200, height: 1500)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            UIColor(red: 0.99, green: 0.98, blue: 0.95, alpha: 1).setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            func stroke(_ path: UIBezierPath, _ color: UIColor, width: CGFloat = 22) {
                color.setStroke()
                path.lineWidth = width
                path.stroke()
            }
            func fill(_ path: UIBezierPath, _ color: UIColor, alpha: CGFloat = 0.85) {
                color.withAlphaComponent(alpha).setFill()
                path.fill()
            }
            func scribbleFill(_ rect: CGRect, _ color: UIColor) {
                let path = UIBezierPath()
                var y = rect.minY
                var flip = false
                while y < rect.maxY {
                    path.move(to: CGPoint(x: flip ? rect.maxX : rect.minX, y: y))
                    path.addLine(to: CGPoint(x: flip ? rect.minX : rect.maxX, y: y + 18))
                    y += 26
                    flip.toggle()
                }
                stroke(path, color.withAlphaComponent(0.7), width: 16)
            }
            func sun(at center: CGPoint, radius: CGFloat) {
                fill(UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), color(2))
                for ray in 0..<10 {
                    let angle = CGFloat(ray) / 10 * .pi * 2
                    let ray = UIBezierPath()
                    ray.move(to: CGPoint(x: center.x + cos(angle) * radius * 1.25, y: center.y + sin(angle) * radius * 1.25))
                    ray.addLine(to: CGPoint(x: center.x + cos(angle) * radius * 1.8, y: center.y + sin(angle) * radius * 1.8))
                    stroke(ray, color(1), width: 18)
                }
            }
            func grass() {
                scribbleFill(CGRect(x: 0, y: 1250, width: 1200, height: 250), color(3))
            }
            func stickPerson(x: CGFloat, height: CGFloat, color c: UIColor) {
                let top = 1250 - height
                stroke(UIBezierPath(ovalIn: CGRect(x: x - 50, y: top, width: 100, height: 100)), c, width: 14)
                let body = UIBezierPath()
                body.move(to: CGPoint(x: x, y: top + 100)); body.addLine(to: CGPoint(x: x, y: top + height * 0.7))
                body.move(to: CGPoint(x: x - 80, y: top + 180)); body.addLine(to: CGPoint(x: x + 80, y: top + 180))
                body.move(to: CGPoint(x: x, y: top + height * 0.7)); body.addLine(to: CGPoint(x: x - 60, y: 1250))
                body.move(to: CGPoint(x: x, y: top + height * 0.7)); body.addLine(to: CGPoint(x: x + 60, y: 1250))
                stroke(body, c, width: 14)
            }

            switch subject {
            case .sunnyHouse:
                sun(at: CGPoint(x: 950, y: 260), radius: 120)
                grass()
                let house = UIBezierPath(rect: CGRect(x: 250, y: 750, width: 500, height: 500))
                fill(house, color(seed + 0)); stroke(house, .darkGray, width: 12)
                let roof = UIBezierPath()
                roof.move(to: CGPoint(x: 200, y: 760)); roof.addLine(to: CGPoint(x: 500, y: 480)); roof.addLine(to: CGPoint(x: 800, y: 760)); roof.close()
                fill(roof, color(5)); stroke(roof, .darkGray, width: 12)
                fill(UIBezierPath(rect: CGRect(x: 440, y: 1020, width: 120, height: 230)), color(4))
                fill(UIBezierPath(rect: CGRect(x: 310, y: 830, width: 110, height: 110)), color(4), alpha: 0.5)
            case .rocket:
                UIColor(red: 0.12, green: 0.16, blue: 0.35, alpha: 1).setFill()
                cg.fill(CGRect(origin: .zero, size: size))
                for star in 0..<25 {
                    let x = CGFloat((star * 397) % 1150), y = CGFloat((star * 613) % 1450)
                    fill(UIBezierPath(ovalIn: CGRect(x: x, y: y, width: 16, height: 16)), color(2), alpha: 1)
                }
                let body = UIBezierPath(roundedRect: CGRect(x: 470, y: 450, width: 260, height: 620), cornerRadius: 130)
                fill(body, .white, alpha: 1)
                for (i, band) in stride(from: 520, to: 1040, by: 90).enumerated() {
                    fill(UIBezierPath(rect: CGRect(x: 490, y: CGFloat(band), width: 220, height: 45)), color(i), alpha: 0.9)
                }
                let flame = UIBezierPath()
                flame.move(to: CGPoint(x: 520, y: 1070)); flame.addQuadCurve(to: CGPoint(x: 680, y: 1070), controlPoint: CGPoint(x: 600, y: 1400))
                fill(flame, color(1), alpha: 1)
            case .family:
                sun(at: CGPoint(x: 180, y: 220), radius: 90)
                grass()
                for (i, h) in [CGFloat(720), 680, 480, 420].enumerated() {
                    stickPerson(x: 220 + CGFloat(i) * 250, height: h, color: color(i * 2 + seed))
                }
                stroke(UIBezierPath(ovalIn: CGRect(x: 1020, y: 1150, width: 130, height: 90)), color(1), width: 14)
            case .truck:
                grass()
                let cargo = UIBezierPath(roundedRect: CGRect(x: 150, y: 750, width: 600, height: 380), cornerRadius: 30)
                fill(cargo, color(0)); stroke(cargo, .darkGray, width: 12)
                let cab = UIBezierPath(roundedRect: CGRect(x: 760, y: 850, width: 300, height: 280), cornerRadius: 40)
                fill(cab, color(0)); stroke(cab, .darkGray, width: 12)
                fill(UIBezierPath(rect: CGRect(x: 820, y: 890, width: 160, height: 100)), color(4), alpha: 0.6)
                for x in [CGFloat(300), 620, 900] {
                    fill(UIBezierPath(ovalIn: CGRect(x: x - 85, y: 1060, width: 170, height: 170)), .darkGray, alpha: 1)
                }
            case .ocean:
                scribbleFill(CGRect(x: 0, y: 0, width: 1200, height: 1500), color(4))
                for (i, fish) in [CGPoint(x: 300, y: 400), CGPoint(x: 800, y: 650), CGPoint(x: 400, y: 1000)].enumerated() {
                    fill(UIBezierPath(ovalIn: CGRect(x: fish.x - 120, y: fish.y - 60, width: 240, height: 120)), color(i + 1), alpha: 1)
                    let tail = UIBezierPath()
                    tail.move(to: CGPoint(x: fish.x + 110, y: fish.y)); tail.addLine(to: CGPoint(x: fish.x + 200, y: fish.y - 70)); tail.addLine(to: CGPoint(x: fish.x + 200, y: fish.y + 70)); tail.close()
                    fill(tail, color(i + 1), alpha: 1)
                }
                fill(UIBezierPath(ovalIn: CGRect(x: 760, y: 1050, width: 260, height: 220)), color(6), alpha: 1)
                for leg in 0..<6 {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: 790 + CGFloat(leg) * 40, y: 1250))
                    path.addQuadCurve(to: CGPoint(x: 770 + CGFloat(leg) * 50, y: 1440), controlPoint: CGPoint(x: 740 + CGFloat(leg) * 60, y: 1350))
                    stroke(path, color(6), width: 26)
                }
            case .dinosaur:
                sun(at: CGPoint(x: 1000, y: 220), radius: 100)
                grass()
                let dino = UIBezierPath()
                dino.move(to: CGPoint(x: 150, y: 1100))
                dino.addQuadCurve(to: CGPoint(x: 700, y: 750), controlPoint: CGPoint(x: 350, y: 700))
                dino.addQuadCurve(to: CGPoint(x: 850, y: 450), controlPoint: CGPoint(x: 820, y: 650))
                dino.addLine(to: CGPoint(x: 1000, y: 470))
                dino.addLine(to: CGPoint(x: 900, y: 600))
                dino.addQuadCurve(to: CGPoint(x: 850, y: 1150), controlPoint: CGPoint(x: 980, y: 950))
                dino.close()
                fill(dino, color(3)); stroke(dino, color(3).withAlphaComponent(0.6), width: 14)
                for x in stride(from: 300, to: 700, by: 90) {
                    fill(UIBezierPath(ovalIn: CGRect(x: CGFloat(x), y: 880, width: 60, height: 60)), color(2), alpha: 1)
                }
                for (i, x) in [CGFloat(150), 1050].enumerated() {
                    fill(UIBezierPath(ovalIn: CGRect(x: x - 50, y: 1150, width: 100, height: 100)), color(6 - i), alpha: 1)
                }
            case .butterfly:
                for (i, wing) in [CGRect(x: 180, y: 350, width: 420, height: 450), CGRect(x: 600, y: 350, width: 420, height: 450),
                                  CGRect(x: 250, y: 780, width: 350, height: 380), CGRect(x: 600, y: 780, width: 350, height: 380)].enumerated() {
                    fill(UIBezierPath(ovalIn: wing), color(i + 4), alpha: 0.8)
                    fill(UIBezierPath(ovalIn: wing.insetBy(dx: wing.width * 0.32, dy: wing.height * 0.32)), color(i + 1), alpha: 0.9)
                }
                fill(UIBezierPath(roundedRect: CGRect(x: 565, y: 400, width: 70, height: 760), cornerRadius: 35), .darkGray, alpha: 1)
            case .nightSky:
                UIColor(red: 0.10, green: 0.12, blue: 0.30, alpha: 1).setFill()
                cg.fill(CGRect(origin: .zero, size: size))
                let moon = UIBezierPath(ovalIn: CGRect(x: 700, y: 180, width: 300, height: 300))
                fill(moon, color(2), alpha: 1)
                for star in 0..<20 {
                    let x = CGFloat(80 + (star * 271) % 1050), y = CGFloat(120 + (star * 491) % 1250)
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: x - 30, y: y)); path.addLine(to: CGPoint(x: x + 30, y: y))
                    path.move(to: CGPoint(x: x, y: y - 30)); path.addLine(to: CGPoint(x: x, y: y + 30))
                    stroke(path, color(2), width: 10)
                }
            case .rainbow:
                sun(at: CGPoint(x: 1000, y: 200), radius: 90)
                for i in 0..<6 {
                    let radius = CGFloat(520 - i * 60)
                    let arc = UIBezierPath(arcCenter: CGPoint(x: 600, y: 1150), radius: radius, startAngle: .pi, endAngle: 0, clockwise: true)
                    stroke(arc, color(i), width: 55)
                }
                grass()
            case .flowers:
                grass()
                let pot = UIBezierPath()
                pot.move(to: CGPoint(x: 400, y: 1000)); pot.addLine(to: CGPoint(x: 800, y: 1000)); pot.addLine(to: CGPoint(x: 740, y: 1350)); pot.addLine(to: CGPoint(x: 460, y: 1350)); pot.close()
                fill(pot, color(1)); stroke(pot, .darkGray, width: 10)
                for (i, x) in [CGFloat(480), 600, 720].enumerated() {
                    let stem = UIBezierPath()
                    stem.move(to: CGPoint(x: x, y: 1000)); stem.addLine(to: CGPoint(x: x + CGFloat(i - 1) * 60, y: 560 + CGFloat(i % 2) * 80))
                    stroke(stem, color(3), width: 18)
                    let head = CGPoint(x: x + CGFloat(i - 1) * 60, y: 520 + CGFloat(i % 2) * 80)
                    fill(UIBezierPath(ovalIn: CGRect(x: head.x - 80, y: head.y - 100, width: 160, height: 180)), color(i == 1 ? 6 : 0), alpha: 1)
                }
                fill(UIBezierPath(ovalIn: CGRect(x: 900, y: 400, width: 110, height: 80)), color(2), alpha: 1)
            case .snowman:
                UIColor(red: 0.80, green: 0.90, blue: 0.98, alpha: 1).setFill()
                cg.fill(CGRect(origin: .zero, size: size))
                for (i, rect) in [CGRect(x: 330, y: 850, width: 540, height: 520), CGRect(x: 410, y: 520, width: 380, height: 370), CGRect(x: 470, y: 290, width: 260, height: 260)].enumerated() {
                    let ball = UIBezierPath(ovalIn: rect)
                    fill(ball, .white, alpha: 1); stroke(ball, color(4).withAlphaComponent(0.4), width: 10)
                    _ = i
                }
                let nose = UIBezierPath()
                nose.move(to: CGPoint(x: 600, y: 420)); nose.addLine(to: CGPoint(x: 720, y: 445)); nose.addLine(to: CGPoint(x: 600, y: 465)); nose.close()
                fill(nose, color(1), alpha: 1)
                for x in stride(from: 430, to: 780, by: 70) {
                    fill(UIBezierPath(rect: CGRect(x: CGFloat(x), y: 535, width: 60, height: 50)), color(x / 70), alpha: 1)
                }
            }
        }
    }
}
#endif
