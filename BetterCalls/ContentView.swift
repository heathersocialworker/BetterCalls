//
//  ContentView.swift
//  BetterCalls
//
//  Created by Tanay Pai on 7/7/25.
//

import SwiftUI
import FirebaseFirestore

class WarmlineService: ObservableObject {
    @Published var contacts: [Contact] = []
    private let db = Firestore.firestore()
    
    func fetchContacts(completion: @escaping () -> Void) {
        db.collection("nami_warmlines").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching contacts: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            let contacts = documents.compactMap { document -> Contact? in
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let phoneNumber = data["phoneNumber"] as? String else {
                    return nil
                }
                
                let id = document.documentID
                let description = data["description"] as? String
                let stateString = data["state"] as? String
                let state = stateString != nil ? USState(rawValue: stateString!) : USState.none
                let hasSpanishSupport = data["hasSpanishSupport"] as? Bool
                let hasChatSupport = data["hasChatSupport"] as? Bool
                let hasTextSupport = data["hasTextSupport"] as? Bool
                
                return Contact(
                    id: document.documentID,
                    name: name,
                    phoneNumber: phoneNumber,
                    description: description,
                    state: state,
                    hasSpanishSupport: hasSpanishSupport,
                    hasChatSupport: hasChatSupport,
                    hasTextSupport: hasTextSupport
                )
            }
            // Sort alphabetically by name
            self?.contacts = contacts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            completion()
        }
    }
}

enum USState: String, CaseIterable, Identifiable {
    case AL, AK, AZ, AR, CA, CO, CT, DE, FL, GA, HI, ID, IL, IN, IA, KS, KY, LA, ME, MD, MA, MI, MN, MS, MO, MT, NE, NV, NH, NJ, NM, NY, NC, ND, OH, OK, OR, PA, RI, SC, SD, TN, TX, UT, VT, VA, WA, WV, WI, WY
    case none
    var id: String { self.rawValue }
    var fullName: String {
        switch self {
        case .AL: return "Alabama"
        case .AK: return "Alaska"
        case .AZ: return "Arizona"
        case .AR: return "Arkansas"
        case .CA: return "California"
        case .CO: return "Colorado"
        case .CT: return "Connecticut"
        case .DE: return "Delaware"
        case .FL: return "Florida"
        case .GA: return "Georgia"
        case .HI: return "Hawaii"
        case .ID: return "Idaho"
        case .IL: return "Illinois"
        case .IN: return "Indiana"
        case .IA: return "Iowa"
        case .KS: return "Kansas"
        case .KY: return "Kentucky"
        case .LA: return "Louisiana"
        case .ME: return "Maine"
        case .MD: return "Maryland"
        case .MA: return "Massachusetts"
        case .MI: return "Michigan"
        case .MN: return "Minnesota"
        case .MS: return "Mississippi"
        case .MO: return "Missouri"
        case .MT: return "Montana"
        case .NE: return "Nebraska"
        case .NV: return "Nevada"
        case .NH: return "New Hampshire"
        case .NJ: return "New Jersey"
        case .NM: return "New Mexico"
        case .NY: return "New York"
        case .NC: return "North Carolina"
        case .ND: return "North Dakota"
        case .OH: return "Ohio"
        case .OK: return "Oklahoma"
        case .OR: return "Oregon"
        case .PA: return "Pennsylvania"
        case .RI: return "Rhode Island"
        case .SC: return "South Carolina"
        case .SD: return "South Dakota"
        case .TN: return "Tennessee"
        case .TX: return "Texas"
        case .UT: return "Utah"
        case .VT: return "Vermont"
        case .VA: return "Virginia"
        case .WA: return "Washington"
        case .WV: return "West Virginia"
        case .WI: return "Wisconsin"
        case .WY: return "Wyoming"
        case .none: return "N/A"
        }
    }
}

struct Contact: Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    let description: String?
    let state: USState?
    let hasSpanishSupport: Bool?
    let hasChatSupport: Bool?
    let hasTextSupport: Bool?
}

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView {
                    ContactsView()
                        .tabItem {
                            Image(systemName: "person.3")
                            Text("Contacts")
                        }
                    
                    FavoritesView()
                        .tabItem {
                            Image(systemName: "heart")
                            Text("Favorites")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.circle")
                            Text("Profile")
                        }
                }
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
}

struct ContactsView: View {
    @StateObject private var warmlineService = WarmlineService()
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingDescriptionSheet: Bool = false
    @State private var selectedContact: Contact? = nil
    @State private var selectedState: USState? = nil // For filtering
    @State private var showingStatePicker: Bool = false // For filter menu
    @State private var searchText: String = "" // For search bar UI
    @State private var filterSpanish: Bool = false
    @State private var filterChat: Bool = false
    @State private var filterText: Bool = false
    @State private var tempSelectedState: USState? = nil
    @State private var tempFilterSpanish: Bool = false
    @State private var tempFilterChat: Bool = false
    @State private var tempFilterText: Bool = false
    @State private var isLoading = true
    @State private var loadTimedOut = false

    var isAnyFilterActive: Bool {
        (selectedState != nil && selectedState != USState.none) || filterSpanish || filterChat || filterText
    }

    var filteredContacts: [Contact] {
        warmlineService.contacts.filter { contact in
            // Search filtering
            let searchMatch = searchText.isEmpty || 
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                (contact.state != nil && contact.state != USState.none && contact.state!.fullName.localizedCaseInsensitiveContains(searchText))
            
            // Filter matching
            let stateMatch = (selectedState == nil || selectedState == USState.none) || contact.state == selectedState
            let spanishMatch = !filterSpanish || (contact.hasSpanishSupport == true)
            let chatMatch = !filterChat || (contact.hasChatSupport == true)
            let textMatch = !filterText || (contact.hasTextSupport == true)
            
            return searchMatch && stateMatch && spanishMatch && chatMatch && textMatch
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("BetterCalls")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                HStack(spacing: 12) {
                    // Search Bar UI (logic to be implemented later)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)

                    // Filter Button/Icon
                    if isAnyFilterActive {
                        HStack(spacing: 0) {
                            Button(action: {
                                tempSelectedState = selectedState
                                tempFilterSpanish = filterSpanish
                                tempFilterChat = filterChat
                                tempFilterText = filterText
                                showingStatePicker = true
                            }) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            Button(action: {
                                selectedState = nil
                                filterSpanish = false
                                filterChat = false
                                filterText = false
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        Button(action: {
                            tempSelectedState = selectedState
                            tempFilterSpanish = filterSpanish
                            tempFilterChat = filterChat
                            tempFilterText = filterText
                            showingStatePicker = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if isLoading && !loadTimedOut {
                    VStack {
                        Spacer()
                        ProgressView("Loading contacts...")
                            .font(.headline)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isLoading && loadTimedOut {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "wifi.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.secondary)
                        Text("Unable to Load Contacts, please check your internet connection.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if filteredContacts.isEmpty {
                            Text("No contacts found matching your criteria.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal)
                                .padding(.top, 24)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredContacts) { contact in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(contact.name)
                                                    .font(.headline)
                                                Text(contact.phoneNumber)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            // Info button to show description
                                            Button(action: {
                                                selectedContact = contact
                                            }) {
                                                Image(systemName: "info.circle")
                                                    .foregroundColor(.blue)
                                                    .font(.title2)
                                                    .padding(12)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            // Favorites button
                                            Button(action: {
                                                if authManager.favoriteContactIDs.contains(contact.id) {
                                                    authManager.removeFavorite(contactID: contact.id)
                                                } else {
                                                    authManager.addFavorite(contactID: contact.id)
                                                }
                                            }) {
                                                Image(systemName: authManager.favoriteContactIDs.contains(contact.id) ? "heart.fill" : "heart")
                                                    .foregroundColor(.pink)
                                                    .font(.title2)
                                                    .padding(12)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            // Phone call button
                                            Button(action: {
                                                makePhoneCall(phoneNumber: contact.phoneNumber)
                                            }) {
                                                Image(systemName: "phone")
                                                    .foregroundColor(.green)
                                                    .font(.title2)
                                                    .padding(12)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(16)
                                    .padding(.horizontal)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Do nothing when tapping elsewhere - this prevents row selection
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
        }
        .onAppear {
            isLoading = true
            loadTimedOut = false
            warmlineService.fetchContacts {
                isLoading = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if isLoading {
                    loadTimedOut = true
                }
            }
            authManager.loadFavorites()
        }
        .sheet(isPresented: $showingStatePicker) {
                NavigationView {
                    Form {
                        Section(header: Text("By State")) {
                            Picker("State", selection: $tempSelectedState) {
                                Text("All States").tag(USState?.none)
                                ForEach(USState.allCases.filter { $0 != .none }, id: \.self) { state in
                                    Text(state.fullName).tag(Optional(state))
                                }
                            }
                        }
                        Section(header: Text("Support Options")) {
                            Toggle("Spanish Support", isOn: $tempFilterSpanish)
                            Toggle("Chat Support", isOn: $tempFilterChat)
                            Toggle("Text Support", isOn: $tempFilterText)
                        }
                        Section {
                            Button("Apply Filters") {
                                selectedState = tempSelectedState
                                filterSpanish = tempFilterSpanish
                                filterChat = tempFilterChat
                                filterText = tempFilterText
                                showingStatePicker = false
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            Button("Clear All") {
                                tempSelectedState = nil
                                tempFilterSpanish = false
                                tempFilterChat = false
                                tempFilterText = false
                            }
                            .foregroundColor(.red)
                            Button("Dismiss") {
                                showingStatePicker = false
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .navigationTitle("Filters")
                    .navigationBarItems(trailing: Button("Done") {
                        selectedState = tempSelectedState
                        filterSpanish = tempFilterSpanish
                        filterChat = tempFilterChat
                        filterText = tempFilterText
                        showingStatePicker = false
                    })
                }
            }
        .sheet(item: $selectedContact) { contact in
            InfoDialogView(contact: contact) { selectedContact = nil }
        }
    }

    // Function to initiate a phone call
    func makePhoneCall(phoneNumber: String) {
        // Clean the phone number to include only digits and the '+' sign
        let cleanedPhoneNumber = phoneNumber.filter("0123456789+".contains)
        if let phoneURL = URL(string: "tel:\(cleanedPhoneNumber)"),
           UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL, options: [:]) { success in
                if success {
                    print("Attempting to call \(phoneNumber)")
                } else {
                    print("Failed to open URL for phone call.")
                }
            }
        } else {
            print("Invalid phone number or cannot open URL: \(phoneNumber)")
        }
    }
}

struct FavoritesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var warmlineService = WarmlineService()
    @State private var selectedContact: Contact? = nil


    

    var favoriteContacts: [Contact] {
        var favContacts : [Contact] = []
        warmlineService.contacts.forEach {ele in
            if authManager.favoriteContactIDs.contains(ele.id){
                favContacts.append(ele)
            }
        }
        return favContacts
    }

    var body: some View {
        VStack {
            if favoriteContacts.isEmpty {
                Spacer()
                Text("No favorites yet.")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        Text("Favorites")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top)
                        ForEach(favoriteContacts) { contact in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(contact.name)
                                            .font(.headline)
                                        Text(contact.phoneNumber)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    // Info button
                                    Button(action: {
                                        selectedContact = contact
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                            .padding(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    // Favorites button
                                    Button(action: {
                                        if authManager.favoriteContactIDs.contains(contact.id) {
                                            authManager.removeFavorite(contactID: contact.id)
                                        } else {
                                            authManager.addFavorite(contactID: contact.id)
                                        }
                                    }) {
                                        Image(systemName: authManager.favoriteContactIDs.contains(contact.id) ? "heart.fill" : "heart")
                                            .foregroundColor(.pink)
                                            .font(.title2)
                                            .padding(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    // Phone call button
                                    Button(action: {
                                        let cleanNumber = contact.phoneNumber.filter("0123456789+".contains)
                                        if let url = URL(string: "tel://\(cleanNumber)"),
                                            UIApplication.shared.canOpenURL(url) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Image(systemName: "phone")
                                            .foregroundColor(.green)
                                            .font(.title2)
                                            .padding(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        // .navigationTitle("Favorites")
        // .navigationBarTitleDisplayMode(.large)
        // .sheet(item: $selectedContact) { contact in
        //     InfoDialogView(contact: contact) { selectedContact = nil }
        // }
        .onAppear {
            warmlineService.fetchContacts {} // Only fetch when tab is shown
            authManager.loadFavorites()      // Also refresh favorites
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                // User Profile Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    if let user = authManager.user {
                        VStack(spacing: 8) {
                            Text(user.displayName?.isEmpty == false ? user.displayName! : "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.email ?? "")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not Signed In")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Account Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Information")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        if let user = authManager.user {
                            ProfileRow(title: "Email", value: user.email ?? "N/A")
                            ProfileRow(title: "Email Verified", value: user.isEmailVerified ? "Yes" : "No")
                        } else {
                            ProfileRow(title: "Status", value: "Not authenticated")
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // App Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ProfileRow(title: "App Version", value: "1.0.0")
                        ProfileRow(title: "Build", value: "1")
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Logout Button
                if authManager.isAuthenticated {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal)
        }
        // .navigationTitle("Profile")
        // .navigationBarTitleDisplayMode(.large)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        
        if title != "Last Sign In" && title != "Build" {
            Divider()
                .padding(.leading, 16)
        }
    }
}

// Reusable InfoRow for card rows
struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .secondary
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
        .font(.body)
        .padding(.vertical, 6)
    }
}

// Reusable GroupedCard for all cards
struct GroupedCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
    }
}

// InfoDialogView with Settings-style design
struct InfoDialogView: View {
    let contact: Contact
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                Text("Contact Information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                GroupedCard {
                    VStack(spacing: 0) {
                        InfoRow(label: "State", value: contact.state?.fullName ?? "N/A")
                        Divider()
                        InfoRow(label: "Phone", value: contact.phoneNumber)
                    }
                }
                Text("Support Options")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                GroupedCard {
                    VStack(spacing: 0) {
                        InfoRow(label: "Spanish Support", value: contact.hasSpanishSupport == true ? "Yes" : "No", valueColor: contact.hasSpanishSupport == true ? .green : .red)
                        Divider()
                        InfoRow(label: "Chat Support", value: contact.hasChatSupport == true ? "Yes" : "No", valueColor: contact.hasChatSupport == true ? .green : .red)
                        Divider()
                        InfoRow(label: "Text Support", value: contact.hasTextSupport == true ? "Yes" : "No", valueColor: contact.hasTextSupport == true ? .green : .red)
                    }
                }
                Spacer()
                Button(action: { onDismiss() }) {
                    Text("Dismiss")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
            .padding(.top, 24)
        }
    }
}

#Preview {
    ContentView()
}
