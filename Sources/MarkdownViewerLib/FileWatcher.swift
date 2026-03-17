import Foundation

public class FileWatcher {
    private var timer: Timer?
    private let url: URL
    private var lastModDate: Date?
    private let onChange: (String) -> Void

    public init(url: URL, onChange: @escaping (String) -> Void) {
        self.url = url
        self.onChange = onChange
        self.lastModDate = Self.modificationDate(for: url)

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    private func checkForChanges() {
        let currentDate = Self.modificationDate(for: url)
        guard currentDate != lastModDate else { return }
        lastModDate = currentDate
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            onChange(text)
        }
    }

    private static func modificationDate(for url: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stop()
    }
}
