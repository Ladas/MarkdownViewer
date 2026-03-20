import Foundation

public struct MermaidTheme: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let initJSON: String // JSON string for mermaid.initialize config

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: MermaidTheme, rhs: MermaidTheme) -> Bool { lhs.id == rhs.id }
}

public enum MermaidThemeManager {

    // Built-in mermaid themes
    private static let builtinThemes: [MermaidTheme] = [
        MermaidTheme(id: "auto", name: "Auto (Light/Dark)", initJSON: ""),
        MermaidTheme(id: "default", name: "Default", initJSON: "{\"theme\":\"default\"}"),
        MermaidTheme(id: "dark", name: "Dark", initJSON: "{\"theme\":\"dark\"}"),
        MermaidTheme(id: "forest", name: "Forest", initJSON: "{\"theme\":\"forest\"}"),
        MermaidTheme(id: "neutral", name: "Neutral", initJSON: "{\"theme\":\"neutral\"}"),
    ]

    public static func loadThemes() -> [MermaidTheme] {
        var themes = builtinThemes
        themes.append(contentsOf: loadPluginThemes())
        return themes
    }

    private static func loadPluginThemes() -> [MermaidTheme] {
        // Look for theme JSON files in Resources/themes/ (gitignored)
        guard let themesDir = Bundle.module.url(
            forResource: "themes", withExtension: nil, subdirectory: "Resources"
        ) else { return [] }

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: themesDir, includingPropertiesForKeys: nil
        ) else { return [] }

        return files.compactMap { url -> MermaidTheme? in
            guard url.pathExtension == "json" else { return nil }
            guard let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let name = json["name"] as? String,
                  let mermaidInit = json["mermaidInit"] as? [String: Any] else { return nil }

            // Re-serialize the mermaidInit to a clean JSON string
            guard let initData = try? JSONSerialization.data(withJSONObject: mermaidInit),
                  let initString = String(data: initData, encoding: .utf8) else { return nil }

            let id = url.deletingPathExtension().lastPathComponent
            return MermaidTheme(id: "plugin-\(id)", name: name, initJSON: initString)
        }
    }
}
