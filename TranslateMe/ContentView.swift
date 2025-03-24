//
//  ContentView.swift
//  TranslateMe
//
//  Created by Julian Valencia on 3/23/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var translationService = TranslationService()
    @State private var originalText = ""
    @State private var translatedText = ""
    @State private var showingHistory = false
    @State private var showAlert = false
    
    let fromLanguage = "en"
    let toLanguage = "es"
    
    var body: some View {
        VStack(spacing: 20) {
            // Input field
            VStack(alignment: .leading) {
                Text("Enter text to translate:")
                    .font(.headline)
                
                TextField("Type here...", text: $originalText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom)
            }
            
            Button(action: {
                translateText()
            }) {
                Text("Translate")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(originalText.isEmpty)
            
            if translationService.isLoading {
                ProgressView()
            }
            
            VStack(alignment: .leading) {
                Text("Translation:")
                    .font(.headline)
                
                Text(translatedText.isEmpty ? "Translation will appear here" : translatedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .minimumScaleFactor(0.5)
            }
            
            Spacer()
            
            HStack {
                Button("View History") {
                    showingHistory = true
                }
                
                Spacer()
                
                Button("Clear History") {
                    showAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .sheet(isPresented: $showingHistory) {
            HistoryView(translations: translationService.translations)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Clear History"),
                message: Text("Are you sure you want to delete all translation history?"),
                primaryButton: .destructive(Text("Delete")) {
                    translationService.deleteAllTranslations()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            print("ContentView appeared - fetching translations")
            translationService.fetchTranslations()
        }
    }
    
    func translateText() {
        guard !originalText.isEmpty else { return }
        
        translationService.translateText(text: originalText, from: fromLanguage, to: toLanguage) { result in
            switch result {
            case .success(let translatedStr):
                self.translatedText = translatedStr
                
                // Save to Firestore
                let newTranslation = Translation(
                    originalText: self.originalText,
                    translatedText: translatedStr,
                    fromLanguage: "English",
                    toLanguage: "Spanish",
                    timestamp: Date()
                )
                
                translationService.saveTranslation(translation: newTranslation)
                
            case .failure(let error):
                self.translatedText = "Error: \(error.localizedDescription)"
            }
        }
    }
}

struct HistoryView: View {
    let translations: [Translation]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if translations.isEmpty {
                    Text("No translation history yet")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(translations) { translation in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(translation.originalText)
                                    .font(.body)
                                Text(translation.translatedText)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("From: \(translation.fromLanguage) → \(translation.toLanguage)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Translation History")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                print("HistoryView appeared - \(translations.count) translations available")
            }
        }
    }
}
