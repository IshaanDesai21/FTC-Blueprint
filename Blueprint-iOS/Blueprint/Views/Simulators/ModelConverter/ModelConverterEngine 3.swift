import SceneKit
import ModelIO
import SceneKit.ModelIO
import Observation

enum ModelFormat: String, CaseIterable {
    case obj, dae, usdz, stl, ply
    case glb, gltf, fbx, threeMF = "3mf", step, stp

    var label: String { rawValue.uppercased() }

    /// Formats SceneKit / Model I/O can actually load on-device. The rest have
    /// no practical from-scratch Swift parser (see engineering note in the app).
    var isNativelySupported: Bool {
        switch self {
        case .obj, .dae, .usdz, .stl, .ply: return true
        case .glb, .gltf, .fbx, .threeMF, .step, .stp: return false
        }
    }
}

struct ModelStats {
    let format: String
    let vertexCount: Int
    let fileSizeBytes: Int
}

enum LoadError: LocalizedError {
    case unsupportedFormat(String)
    case loadFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let ext):
            return "\".\(ext)\" isn't supported on-device. CAD/exchange formats like STEP, FBX, 3MF, and GLB rely on a full parsing library with no practical Swift equivalent \u{2014} convert to OBJ, STL, PLY, or USDZ on desktop first."
        case .loadFailed(let msg):
            return "Couldn't load this file: \(msg)"
        }
    }
}

@Observable
final class ModelConverterEngine {
    var scene: SCNScene?
    var stats: ModelStats?
    var errorMessage: String?
    var isLoading = false
    var fileName: String?

    func load(url: URL) {
        isLoading = true
        errorMessage = nil
        stats = nil
        scene = nil

        let ext = url.pathExtension.lowercased()
        fileName = url.lastPathComponent

        guard let format = ModelFormat(rawValue: ext) else {
            errorMessage = LoadError.unsupportedFormat(ext).errorDescription
            isLoading = false
            return
        }

        guard format.isNativelySupported else {
            errorMessage = LoadError.unsupportedFormat(ext).errorDescription
            isLoading = false
            return
        }

        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0

        // SceneKit/Model I/O can raise an Objective-C NSException on malformed files,
        // which a Swift `do/catch` cannot intercept and which would otherwise crash
        // the whole process. Route the risky parsing through an Obj-C exception trap
        // so a bad file surfaces as an on-screen error instead of a hard crash.
        var loadedScene: SCNScene?
        var caughtError: NSError?
        do {
            try ExceptionCatcher.catchException {
                switch format {
                case .usdz, .dae, .obj:
                    loadedScene = try? SCNScene(url: url, options: [.checkConsistency: true])
                case .stl, .ply:
                    let asset = MDLAsset(url: url)
                    asset.loadTextures()
                    loadedScene = SCNScene(mdlAsset: asset)
                default:
                    break
                }
            }
        } catch {
            caughtError = error as NSError
        }

        if let caughtError {
            errorMessage = LoadError.loadFailed(caughtError.localizedDescription).errorDescription
        } else if let loadedScene {
            normalize(loadedScene)
            applyDefaultMaterial(loadedScene.rootNode)

            let vertCount = countVertices(loadedScene.rootNode)
            stats = ModelStats(format: format.label, vertexCount: vertCount, fileSizeBytes: fileSize)
            scene = loadedScene
        } else {
            errorMessage = LoadError.loadFailed("Couldn't parse this file's geometry.").errorDescription
        }

        isLoading = false
    }

    func reset() {
        scene = nil
        stats = nil
        errorMessage = nil
        fileName = nil
    }

    /// Mirrors the web tool's fitAndPlace: scale so the largest bounding-box
    /// dimension is 2 units, then re-center at the origin.
    private func normalize(_ scene: SCNScene) {
        let (min, max) = scene.rootNode.boundingBox
        let size = SCNVector3(max.x - min.x, max.y - min.y, max.z - min.z)
        let largest = Swift.max(size.x, Swift.max(size.y, size.z))
        guard largest > 0 else { return }

        let scale = 2 / largest
        scene.rootNode.scale = SCNVector3(scale, scale, scale)

        let center = SCNVector3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
        scene.rootNode.position = SCNVector3(-center.x * scale, -center.y * scale, -center.z * scale)
    }

    private func applyDefaultMaterial(_ node: SCNNode) {
        if let geometry = node.geometry, geometry.materials.isEmpty {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: 0.49, green: 0.88, blue: 1.0, alpha: 1)
            material.roughness.contents = 0.3
            material.metalness.contents = 0.7
            geometry.materials = [material]
        }
        for child in node.childNodes {
            applyDefaultMaterial(child)
        }
    }

    private func countVertices(_ node: SCNNode) -> Int {
        var count = 0
        if let geometry = node.geometry {
            for source in geometry.sources where source.semantic == .vertex {
                count += source.vectorCount
            }
        }
        for child in node.childNodes {
            count += countVertices(child)
        }
        return count
    }
}
