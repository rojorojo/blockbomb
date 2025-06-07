import SwiftUI

struct BlockColors {
    static let slate = Color(red: 0.392, green: 0.455, blue: 0.545)
    static let gray = Color(red: 0.420, green: 0.447, blue: 0.502)
    static let zinc = Color(red: 0.443, green: 0.443, blue: 0.478)
    static let neutral = Color(red: 0.451, green: 0.451, blue: 0.451)
    static let stone = Color(red: 0.471, green: 0.443, blue: 0.424)

    static let red = Color(red: 0.937, green: 0.267, blue: 0.267)
    static let orange = Color(red: 0.976, green: 0.451, blue: 0.086)
    static let amber = Color(red: 0.961, green: 0.620, blue: 0.043)
    static let yellow = Color(red: 0.918, green: 0.702, blue: 0.031)
    static let lime = Color(red: 0.518, green: 0.800, blue: 0.086)
    static let green = Color(red: 0.133, green: 0.773, blue: 0.369)
    static let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)
    static let teal = Color(red: 0.078, green: 0.722, blue: 0.651)
    static let cyan = Color(red: 0.024, green: 0.714, blue: 0.831)
    static let sky = Color(red: 0.055, green: 0.647, blue: 0.914)
    static let blue = Color(red: 0.231, green: 0.510, blue: 0.965)
    static let indigo = Color(red: 0.388, green: 0.400, blue: 0.945)
    static let violet = Color(red: 0.545, green: 0.361, blue: 0.965)
    static let purple = Color(red: 0.659, green: 0.333, blue: 0.969)
    static let fuchsia = Color(red: 0.851, green: 0.275, blue: 0.937)
    static let pink = Color(red: 0.925, green: 0.282, blue: 0.600)
    static let rose = Color(red: 0.957, green: 0.247, blue: 0.369)
    
    static let bg = Color(red: 0.02, green: 0, blue: 0.22)

static func randomBlockColor() -> Color {
        let blockColors: [Color] = [
    red,
    orange,
    amber,
    yellow,
    lime,
    green,
    emerald,
    teal,
    cyan,
    sky,
    blue,
    indigo,
    violet,
    purple,
    fuchsia,
    pink,
    rose
]
        return blockColors.randomElement()!
    }

    
}
