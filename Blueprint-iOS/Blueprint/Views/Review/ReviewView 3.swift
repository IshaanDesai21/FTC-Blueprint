import SwiftUI

struct ReviewView: View {
    @State private var kind: ReviewKind = .portfolio

    var body: some View {
        Form {
            SwiftUI.Section {
                Picker("Review type", selection: $kind) {
                    ForEach(ReviewKind.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            ReviewFormSection(kind: kind)
                .id(kind)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Get a Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReviewFormSection: View {
    let kind: ReviewKind

    @State private var team = ""
    @State private var email = ""
    @State private var link = ""
    @State private var notes = ""
    @State private var state: SubmitState = .idle

    enum SubmitState: Equatable {
        case idle, sending, sent, failed(String)
    }

    var body: some View {
        SwiftUI.Section {
            Text(kind.description)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }

        SwiftUI.Section("Team Name & Number") {
            TextField("e.g. 12345", text: $team)
                .textInputAutocapitalization(.words)
        }

        SwiftUI.Section("Contact Email") {
            TextField("you@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }

        SwiftUI.Section(kind.linkPlaceholder) {
            TextField(kind.linkPlaceholder, text: $link)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }

        SwiftUI.Section("Notes") {
            TextField(kind.notesPlaceholder, text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }

        SwiftUI.Section {
            submitButton
            if case .failed(let message) = state {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }
            if case .sent = state {
                Label("Sent! We'll reply to your email shortly.", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.accentGreen)
            }
        }
    }

    private var canSubmit: Bool {
        !team.isEmpty && !email.isEmpty && !link.isEmpty && state != .sending
    }

    private var submitButton: some View {
        Button(action: submit) {
            if state == .sending {
                ProgressView()
            } else {
                Text("Send for Review")
            }
        }
        .disabled(!canSubmit)
    }

    private func submit() {
        guard let url = URL(string: "https://api.web3forms.com/submit") else { return }
        state = .sending

        let payload: [String: String] = [
            "access_key": kind.accessKey,
            "subject": kind.subject,
            "team": team,
            "email": email,
            kind.linkFieldName: link,
            "notes": notes
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                        state = .sent
                        team = ""; email = ""; link = ""; notes = ""
                    } else {
                        state = .failed("Something went wrong. Please try again.")
                    }
                }
            } catch {
                await MainActor.run {
                    state = .failed("Couldn't reach the server. Check your connection and try again.")
                }
            }
        }
    }
}
