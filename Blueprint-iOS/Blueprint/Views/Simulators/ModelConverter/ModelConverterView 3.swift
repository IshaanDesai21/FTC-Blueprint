import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct ModelConverterView: View {
    @State private var engine = ModelConverterEngine()
    @State private var showImporter = false

    private let supportedTypes: [UTType] = [
        UTType(filenameExtension: "obj"), UTType(filenameExtension: "dae"),
        UTType(filenameExtension: "usdz"), UTType(filenameExtension: "stl"),
        UTType(filenameExtension: "ply")
    ].compactMap { $0 }

    var body: some View {
        Form {
            SwiftUI.Section {
                Text("Preview 3D robot parts on your phone. Natively supports OBJ, Collada (DAE), USDZ, STL, and PLY.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let scene = engine.scene {
                    SceneKitView(scene: scene)
                        .frame(height: 320)
                        .listRowInsets(EdgeInsets())
                } else {
                    dropZone
                        .listRowInsets(EdgeInsets())
                }

                if let error = engine.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            if let stats = engine.stats {
                SwiftUI.Section("File Info") {
                    statRow("Format", stats.format)
                    statRow("Vertices", stats.vertexCount.formatted())
                    statRow("File Size", formatBytes(stats.fileSizeBytes))
                }

                SwiftUI.Section {
                    Button("Choose Another File") { showImporter = true }
                    Button("Clear", role: .destructive) { engine.reset() }
                }
            } else {
                SwiftUI.Section {
                    Button("Choose a File") { showImporter = true }
                }
            }

            SwiftUI.Section("Not Supported On-Device") {
                Text("STEP, STP, FBX, 3MF, GLB, and GLTF require a full CAD/format parsing library that has no practical Swift equivalent. Convert to OBJ, STL, or USDZ using desktop software first, then preview here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Model Converter")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: supportedTypes.isEmpty ? [.item] : supportedTypes) { result in
            switch result {
            case .success(let url):
                engine.load(url: url)
            case .failure(let error):
                engine.errorMessage = error.localizedDescription
            }
        }
    }

    private var dropZone: some View {
        Button {
            showImporter = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.accentCyan)
                Text("Tap to choose a 3D file")
                    .font(.subheadline.weight(.medium))
                Text("OBJ \u{00B7} DAE \u{00B7} USDZ \u{00B7} STL \u{00B7} PLY")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 50)
        }
        .buttonStyle(.plain)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct SceneKitView: UIViewRepresentable {
    let scene: SCNScene

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = true
        view.backgroundColor = .clear
        configureScene(view)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if uiView.scene !== scene {
            configureScene(uiView)
        }
    }

    private func configureScene(_ view: SCNView) {
        setupLighting(scene)
        setupCamera(scene)
        view.scene = scene
    }

    private func setupCamera(_ scene: SCNScene) {
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 50
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(2, 1.5, 2)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLighting(_ scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 900
        key.position = SCNVector3(5, 10, 7)
        key.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .omni
        fill.light?.color = UIColor(red: 0.49, green: 0.88, blue: 1.0, alpha: 1)
        fill.light?.intensity = 300
        fill.position = SCNVector3(-5, 5, -5)
        scene.rootNode.addChildNode(fill)

        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor.clear
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
    }
}
