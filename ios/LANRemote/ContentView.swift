import SwiftUI

struct ContentView: View {
    @AppStorage("pystream_host_address")
    private var savedHostAddress = ""

    @State private var hostAddress = ""
    @State private var remoteURL: URL?
    @State private var connectionError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let remoteURL {
                    RemoteWebView(url: remoteURL)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    connectionScreen
                }
            }
            .navigationTitle("PyStream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if remoteURL != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Disconnect") {
                            remoteURL = nil
                        }
                    }
                }
            }
            .onAppear {
                if hostAddress.isEmpty {
                    hostAddress = savedHostAddress
                }
            }
        }
    }

    private var connectionScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "display")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("PyStream")
                .font(.largeTitle.bold())

            Text("Connect to your Windows desktop over your local network.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("HOST ADDRESS")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                TextField("192.168.1.100:8765", text: $hostAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.go)
                    .onSubmit(connect)
            }
            .padding(.horizontal)

            if let connectionError {
                Text(connectionError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: connect) {
                Label("Connect", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        .orange,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .foregroundStyle(.black)
            }
            .padding(.horizontal)
            .disabled(
                hostAddress.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            )

            Spacer()
        }
        .padding()
    }

    private func connect() {
        connectionError = nil

        let enteredAddress = hostAddress.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !enteredAddress.isEmpty else {
            connectionError = "Enter your Windows PC's LAN address."
            return
        }

        let addressWithScheme: String

        if enteredAddress.hasPrefix("http://") ||
            enteredAddress.hasPrefix("https://") {
            addressWithScheme = enteredAddress
        } else {
            addressWithScheme = "http://" + enteredAddress
        }

        guard let url = URL(string: addressWithScheme),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme),
              url.host != nil else {
            connectionError =
                "Invalid address. Example: 192.168.1.100:8765"
            return
        }

        savedHostAddress = enteredAddress
        remoteURL = url
    }
}