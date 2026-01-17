import SwiftUI
import UniformTypeIdentifiers

/// View for importing tasks from files
struct ImportView: View {
    @Bindable var coordinator: ImportCoordinator

    @State private var selectedSource: ImportSource = .timeCapsule
    @State private var isFilePickerPresented = false
    @State private var isDragging = false
    @State private var skipDuplicates = true
    @State private var defaultTags: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                sourceSection
                dropZone
                previewSection
                resultSection
            }
            .padding()
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Import Tasks")
                .font(.title)
                .fontWeight(.bold)

            Text("Bring your tasks from other apps or restore from a backup.")
                .foregroundStyle(.secondary)
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Source")
                .font(.headline)

            Picker("Source", selection: $selectedSource) {
                ForEach(ImportSource.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedSource.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dropZone: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundStyle(isDragging ? .blue : .secondary.opacity(0.5))
                    .frame(height: 120)
                    .background(isDragging ? Color.blue.opacity(0.05) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("Drop file here or click to browse")
                        .foregroundStyle(.secondary)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers)
            }
            .onTapGesture {
                isFilePickerPresented = true
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        if coordinator.isProcessing {
            ProgressView("Processing file...")
                .frame(maxWidth: .infinity)
                .padding()
        } else if !coordinator.previewTasks.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Preview")
                        .font(.headline)

                    Spacer()

                    Text("\(coordinator.previewTasks.count) tasks")
                        .foregroundStyle(.secondary)
                }

                // Warnings
                if let preview = coordinator.currentPreview, !preview.warnings.isEmpty {
                    ForEach(preview.warnings, id: \.self) { warning in
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text(warning)
                                .font(.caption)
                        }
                    }
                }

                // Task list preview
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(coordinator.previewTasks.prefix(5)) { task in
                        TaskPreviewRow(task: task)
                    }

                    if coordinator.previewTasks.count > 5 {
                        Text("...and \(coordinator.previewTasks.count - 5) more")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }

                // Import options
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Skip duplicate tasks", isOn: $skipDuplicates)

                    HStack {
                        Text("Add tags:")
                        TextField("tag1, tag2", text: $defaultTags)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                    }
                }

                // Action buttons
                HStack {
                    Button("Cancel") {
                        coordinator.cancelImport()
                        errorMessage = nil
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Import \(coordinator.previewTasks.count) Tasks") {
                        performImport()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let result = coordinator.importResult {
            HStack {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(result.isSuccess ? .green : .orange)

                VStack(alignment: .leading) {
                    Text(result.isSuccess ? "Import complete!" : "Import completed with issues")
                        .fontWeight(.medium)
                    Text(result.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background((result.isSuccess ? Color.green : Color.orange).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Helpers

    private var allowedTypes: [UTType] {
        [.json, .commaSeparatedText, .plainText]
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                loadFile(url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    loadFile(url)
                }
            }
        }

        return true
    }

    private func loadFile(_ url: URL) {
        errorMessage = nil

        // Auto-detect source if possible
        if let detected = coordinator.detectSource(from: url) {
            selectedSource = detected
        }

        Task {
            do {
                try await coordinator.preview(from: url, source: selectedSource)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func performImport() {
        let tags = defaultTags
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let options = ImportOptions(
            skipDuplicates: skipDuplicates,
            defaultTags: tags
        )

        Task {
            do {
                _ = try await coordinator.confirmImport(options: options)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Supporting Views

private struct TaskPreviewRow: View {
    let task: TaskItem

    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isCompleted ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .lineLimit(1)

                if !task.tags.isEmpty {
                    Text(task.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(task.priority.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
