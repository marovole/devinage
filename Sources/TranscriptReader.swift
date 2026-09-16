import Foundation

// ┌────────────────────────────────────────────────────────┐
// │  TranscriptReader —— 扫描 ~/.local/share/devin/cli/    │
// │  transcripts/*.json(ATIF 格式),提取 final_metrics       │
// │  会话起止时间用文件创建/修改时间,跳过 steps 解析          │
// │  mtime+size 做缓存键,未变化的文件不重解析               │
// └────────────────────────────────────────────────────────┘

struct TranscriptReader {
    let directory: URL
    private var cache: [String: (mtime: Date, size: Int, usage: SessionUsage)] = [:]

    init(directory: URL) { self.directory = directory }

    mutating func scan() -> [SessionUsage] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey, .fileSizeKey],
            options: .skipsHiddenFiles
        )) ?? []

        var seen = Set<String>()
        var result: [SessionUsage] = []
        for url in files where url.pathExtension == "json" {
            let id = url.deletingPathExtension().lastPathComponent
            seen.insert(id)
            let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey, .fileSizeKey])
            let mtime = attrs?.contentModificationDate ?? .distantPast
            let size = attrs?.fileSize ?? 0

            if let hit = cache[id], hit.mtime == mtime, hit.size == size {
                result.append(hit.usage)
                continue
            }
            guard var usage = Self.parse(url: url, id: id) else { continue }
            usage.startedAt = attrs?.creationDate ?? mtime
            usage.lastActivity = mtime
            cache[id] = (mtime, size, usage)
            result.append(usage)
        }
        // 清理已被删除 transcript 的缓存
        cache = cache.filter { seen.contains($0.key) }
        return result
    }

    /// 只解三个键:session_id 用文件名,model 取 agent.model_name,指标取 final_metrics
    private static func parse(url: URL, id: String) -> SessionUsage? {
        guard let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let metrics = root["final_metrics"] as? [String: Any]
        else { return nil }

        var usage = SessionUsage(id: id)
        usage.stats = TokenStats(
            prompt: metrics["total_prompt_tokens"] as? Int ?? 0,
            completion: metrics["total_completion_tokens"] as? Int ?? 0,
            cached: metrics["total_cached_tokens"] as? Int ?? 0
        )
        usage.steps = metrics["total_steps"] as? Int ?? 0
        usage.model = (root["agent"] as? [String: Any])?["model_name"] as? String
        return usage
    }
}
