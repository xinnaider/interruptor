import AppKit
import Foundation

// MARK: - Appcast

struct Appcast: Decodable {
    let version: String
    let shortVersion: String
    let downloadURL: String
    let releasePage: String
    let minimumSystemVersion: String
}

// MARK: - Updater

enum Updater {
    static let appcastURL = URL(string: "https://interruptor.jfernando.dev/appcast.json")!
    static let fallbackReleasesURL = URL(string: "https://api.github.com/repos/xinnaider/interruptor/releases/latest")!

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    struct UpdateInfo: Equatable {
        let version: String
        let downloadURL: URL
        let releasePage: URL
    }

    static func check() async -> UpdateInfo? {
        if let info = await fetchAppcast() { return info }
        return await fetchGitHubRelease()
    }

    private static func fetchAppcast() async -> UpdateInfo? {
        do {
            let (data, response) = try await URLSession.shared.data(from: appcastURL)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            let cast = try JSONDecoder().decode(Appcast.self, from: data)
            guard isNewer(cast.version, than: currentVersion),
                  let dl = URL(string: cast.downloadURL),
                  let page = URL(string: cast.releasePage) else { return nil }
            return UpdateInfo(version: cast.version, downloadURL: dl, releasePage: page)
        } catch {
            return nil
        }
    }

    private static func fetchGitHubRelease() async -> UpdateInfo? {
        struct GHRelease: Decodable {
            let tagName: String
            let htmlURL: String
            let assets: [Asset]
            enum CodingKeys: String, CodingKey {
                case tagName = "tag_name"
                case htmlURL = "html_url"
                case assets
            }
            struct Asset: Decodable {
                let name: String
                let browserDownloadURL: String
                enum CodingKeys: String, CodingKey {
                    case name
                    case browserDownloadURL = "browser_download_url"
                }
            }
        }

        do {
            var req = URLRequest(url: fallbackReleasesURL)
            req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: req)
            let release = try JSONDecoder().decode(GHRelease.self, from: data)
            let version = release.tagName.hasPrefix("v")
                ? String(release.tagName.dropFirst())
                : release.tagName
            guard isNewer(version, than: currentVersion),
                  let page = URL(string: release.htmlURL) else { return nil }

            let zip = release.assets.first { $0.name.hasSuffix(".zip") }
            guard let zip, let dl = URL(string: zip.browserDownloadURL) else { return nil }
            return UpdateInfo(version: version, downloadURL: dl, releasePage: page)
        } catch {
            return nil
        }
    }

    /// Compara semver simples: 1.2.3 > 1.2.0
    static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        let n = max(r.count, l.count)
        for i in 0..<n {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }

    @MainActor
    static func promptIfNeeded(silent: Bool = true) async {
        guard let info = await check() else { return }
        let alert = NSAlert()
        alert.messageText = String(
            localized: "update.title",
            defaultValue: "Nova versão disponível"
        )
        alert.informativeText = String(
            format: String(localized: "update.body", defaultValue: "Você está na v%@. A v%@ já está no ar."),
            currentVersion,
            info.version
        )
        alert.addButton(withTitle: String(localized: "update.download", defaultValue: "Baixar"))
        alert.addButton(withTitle: String(localized: "update.later", defaultValue: "Depois"))
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(info.downloadURL)
        }
    }
}
