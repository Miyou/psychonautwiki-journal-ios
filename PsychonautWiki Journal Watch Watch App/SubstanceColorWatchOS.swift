// Copyright (c) 2025. Michael Young.
// This file is part of PsychonautWiki Journal Watch Watch App.
//
// PsychonautWiki Journal Watch Watch App is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public Licence as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// PsychonautWiki Journal Watch Watch App is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with PsychonautWiki Journal Watch Watch App. If not, see https://www.gnu.org/licenses/gpl-3.0.en.html.

import SwiftUI

// watchOS-compatible SubstanceColor enum and extension
enum SubstanceColor: String, CaseIterable, Identifiable, Codable, Comparable {
    static func < (lhs: SubstanceColor, rhs: SubstanceColor) -> Bool {
        lhs.sortValue < rhs.sortValue
    }

    case blue = "BLUE"
    case brown = "BROWN"
    case cyan = "CYAN"
    case green = "GREEN"
    case indigo = "INDIGO"
    case mint = "MINT"
    case orange = "ORANGE"
    case pink = "PINK"
    case purple = "PURPLE"
    case red = "RED"
    case teal = "TEAL"
    case yellow = "YELLOW"
    case fireEngineRed = "FIRE_ENGINE_RED"
    case coral = "CORAL"
    case tomato = "TOMATO"
    case cinnabar = "CINNABAR"
    case rust = "RUST"
    case orangeRed = "ORANGE_RED"
    case auburn = "AUBURN"
    case saddleBrown = "SADDLE_BROWN"
    case darkOrange = "DARK_ORANGE"
    case darkGold = "DARK_GOLD"
    case khaki = "KHAKI"
    case bronze = "BRONZE"
    case gold = "GOLD"
    case olive = "OLIVE"
    case oliveDrab = "OLIVE_DRAB"
    case darkOliveGreen = "DARK_OLIVE_GREEN"
    case mossGreen = "MOSS_GREEN"
    case limeGreen = "LIME_GREEN"
    case lime = "LIME"
    case forestGreen = "FOREST_GREEN"
    case seaGreen = "SEA_GREEN"
    case jungleGreen = "JUNGLE_GREEN"
    case lightSeaGreen = "LIGHT_SEA_GREEN"
    case darkTurquoise = "DARK_TURQUOISE"
    case dodgerBlue = "DODGER_BLUE"
    case royalBlue = "ROYAL_BLUE"
    case deepLavender = "DEEP_LAVENDER"
    case blueViolet = "BLUE_VIOLET"
    case darkViolet = "DARK_VIOLET"
    case heliotrope = "HELIOTROPE"
    case byzantium = "BYZANTIUM"
    case magenta = "MAGENTA"
    case darkMagenta = "DARK_MAGENTA"
    case fuchsia = "FUCHSIA"
    case deepPink = "DEEP_PINK"
    case grayishMagenta = "GRAYISH_MAGENTA"
    case hotPink = "HOT_PINK"
    case jazzberryJam = "JAZZBERRY_JAM"
    case maroon = "MAROON"

    var id: SubstanceColor {
        self
    }

    var sortValue: Int {
        switch self {
        case .blue: return 0
        case .brown: return 1
        case .cyan: return 2
        case .green: return 3
        case .indigo: return 4
        case .mint: return 5
        case .orange: return 6
        case .pink: return 7
        case .purple: return 8
        case .red: return 9
        case .teal: return 10
        case .yellow: return 11
        case .fireEngineRed: return 22
        case .coral: return 13
        case .tomato: return 14
        case .cinnabar: return 15
        case .rust: return 16
        case .orangeRed: return 17
        case .auburn: return 18
        case .saddleBrown: return 19
        case .darkOrange: return 20
        case .darkGold: return 21
        case .khaki: return 22
        case .bronze: return 23
        case .gold: return 24
        case .olive: return 25
        case .oliveDrab: return 26
        case .darkOliveGreen: return 27
        case .mossGreen: return 28
        case .limeGreen: return 29
        case .lime: return 30
        case .forestGreen: return 31
        case .seaGreen: return 32
        case .jungleGreen: return 33
        case .lightSeaGreen: return 34
        case .darkTurquoise: return 35
        case .dodgerBlue: return 36
        case .royalBlue: return 37
        case .deepLavender: return 38
        case .blueViolet: return 39
        case .darkViolet: return 40
        case .heliotrope: return 41
        case .byzantium: return 42
        case .magenta: return 43
        case .darkMagenta: return 44
        case .fuchsia: return 45
        case .deepPink: return 46
        case .grayishMagenta: return 47
        case .hotPink: return 48
        case .jazzberryJam: return 49
        case .maroon: return 50
        }
    }
}

extension SubstanceColor {
    var swiftUIColor: Color {
        return watchOSColor
    }
    
    var watchOSColor: Color {
        switch self {
        case .blue: return Color.blue
        case .brown: return Color.brown
        case .cyan: return Color.cyan
        case .green: return Color.green
        case .indigo: return Color.indigo
        case .mint: return Color.mint
        case .orange: return Color.orange
        case .pink: return Color.pink
        case .purple: return Color.purple
        case .red: return Color.red
        case .teal: return Color.teal
        case .yellow: return Color.yellow
        case .fireEngineRed: return Color(red: 0.9294117647058824, green: 0.054901960784313725, blue: 0.023529411764705882)
        case .coral: return Color(red: 0.7058823529411765, green: 0.3607843137254902, blue: 0.3333333333333333)
        case .tomato: return Color(red: 0.7058823529411765, green: 0.27058823529411763, blue: 0.19607843137254902)
        case .cinnabar: return Color(red: 0.8901960784313725, green: 0.1411764705882353, blue: 0.0)
        case .rust: return Color(red: 0.7803921568627451, green: 0.3176470588235294, blue: 0.22745098039215686)
        case .orangeRed: return Color(red: 0.803921568627451, green: 0.21568627450980393, blue: 0.0)
        case .auburn: return Color(red: 0.6784313725490196, green: 0.24313725490196078, blue: 0.0)
        case .saddleBrown: return Color(red: 0.5450980392156862, green: 0.27058823529411763, blue: 0.07450980392156863)
        case .darkOrange: return Color(red: 0.6078431372549019, green: 0.32941176470588235, blue: 0.0)
        case .darkGold: return Color(red: 0.6627450980392157, green: 0.40784313725490196, blue: 0.0)
        case .khaki: return Color(red: 0.5019607843137255, green: 0.4470588235294118, blue: 0.33725490196078434)
        case .bronze: return Color(red: 0.47058823529411764, green: 0.3411764705882353, blue: 0.0)
        case .gold: return Color(red: 0.5098039215686274, green: 0.42745098039215684, blue: 0.0)
        case .olive: return Color(red: 0.4, green: 0.3803921568627451, blue: 0.0)
        case .oliveDrab: return Color(red: 0.43529411764705883, green: 0.4627450980392157, blue: 0.03137254901960784)
        case .darkOliveGreen: return Color(red: 0.3333333333333333, green: 0.4196078431372549, blue: 0.1843137254901961)
        case .mossGreen: return Color(red: 0.30980392156862746, green: 0.47843137254901963, blue: 0.1568627450980392)
        case .limeGreen: return Color(red: 0.0, green: 0.5098039215686274, blue: 0.0)
        case .lime: return Color(red: 0.12549019607843137, green: 0.5098039215686274, blue: 0.12549019607843137)
        case .forestGreen: return Color(red: 0.10980392156862745, green: 0.4470588235294118, blue: 0.10980392156862745)
        case .seaGreen: return Color(red: 0.14901960784313725, green: 0.4470588235294118, blue: 0.2784313725490196)
        case .jungleGreen: return Color(red: 0.011764705882352941, green: 0.5333333333333333, blue: 0.34509803921568627)
        case .lightSeaGreen: return Color(red: 0.08627450980392157, green: 0.5019607843137255, blue: 0.47843137254901963)
        case .darkTurquoise: return Color(red: 0.0, green: 0.5137254901960784, blue: 0.5254901960784314)
        case .dodgerBlue: return Color(red: 0.09411764705882353, green: 0.4549019607843137, blue: 0.803921568627451)
        case .royalBlue: return Color(red: 0.2549019607843137, green: 0.4117647058823529, blue: 0.8823529411764706)
        case .deepLavender: return Color(red: 0.5294117647058824, green: 0.3058823529411765, blue: 0.996078431372549)
        case .blueViolet: return Color(red: 0.5411764705882353, green: 0.16862745098039217, blue: 0.8862745098039215)
        case .darkViolet: return Color(red: 0.5803921568627451, green: 0.0, blue: 0.8274509803921568)
        case .heliotrope: return Color(red: 0.592156862745098, green: 0.36470588235294116, blue: 0.6862745098039216)
        case .byzantium: return Color(red: 0.6, green: 0.1607843137254902, blue: 0.7411764705882353)
        case .magenta: return Color(red: 0.803921568627451, green: 0.0, blue: 0.803921568627451)
        case .darkMagenta: return Color(red: 0.5450980392156862, green: 0.0, blue: 0.5450980392156862)
        case .fuchsia: return Color(red: 0.7411764705882353, green: 0.23529411764705882, blue: 0.5058823529411764)
        case .deepPink: return Color(red: 0.803921568627451, green: 0.06274509803921569, blue: 0.4588235294117647)
        case .grayishMagenta: return Color(red: 0.6313725490196078, green: 0.3764705882352941, blue: 0.5019607843137255)
        case .hotPink: return Color(red: 0.7058823529411765, green: 0.2901960784313726, blue: 0.49411764705882355)
        case .jazzberryJam: return Color(red: 0.7254901960784313, green: 0.17647058823529413, blue: 0.36470588235294116)
        case .maroon: return Color(red: 0.7450980392156863, green: 0.19215686274509805, blue: 0.26666666666666666)
        }
    }
}