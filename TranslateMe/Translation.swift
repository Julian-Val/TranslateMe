//
//  Translation.swift
//  TranslateMe
//
//  Created by Julian Valencia on 3/23/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
struct Translation: Identifiable, Codable {
    @DocumentID var id: String?
    let originalText: String
    let translatedText: String
    let fromLanguage: String
    let toLanguage: String
    let timestamp: Date
}

// Simple API response structure
struct TranslationResponse: Codable {
    let responseData: ResponseData
    
    struct ResponseData: Codable {
        let translatedText: String
    }
}

class TranslationService: ObservableObject {
    @Published var translations: [Translation] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func fetchTranslations() {
        print("Fetching translations from Firestore")
        
        db.collection("translations")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching translations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in Firestore")
                    return
                }
                
                print("Found \(documents.count) translations in Firestore")
                
                self.translations = documents.compactMap { document -> Translation? in
                    do {
                        let translation = try document.data(as: Translation.self)
                        return translation
                    } catch {
                        print("Error decoding document \(document.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }
                
                print("Successfully loaded \(self.translations.count) translations")
            }
    }
    
    func saveTranslation(translation: Translation) {
        print("Saving new translation: \(translation.originalText) -> \(translation.translatedText)")
        
        do {
            let docRef = try db.collection("translations").addDocument(from: translation)
            print("Successfully saved translation with ID: \(docRef.documentID)")
        } catch {
            print("Error saving translation: \(error.localizedDescription)")
        }
    }
    
    func deleteAllTranslations() {
        print("Attempting to delete all translations")
        
        db.collection("translations").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents for deletion: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents to delete")
                return
            }
            
            print("Deleting \(documents.count) translations")
            
            let batch = self.db.batch()
            
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error deleting translations: \(error.localizedDescription)")
                } else {
                    print("All translations successfully deleted")
                }
            }
        }
    }
    
    func translateText(text: String, from: String, to: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid text"])))
            return
        }
        
        self.isLoading = true
        print("Translating text: \(text)")
        
        let urlString = "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=\(from)|\(to)"
        guard let url = URL(string: urlString) else {
            self.isLoading = false
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Translation API error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    print("No data received from translation API")
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(TranslationResponse.self, from: data)
                    print("Translation successful: \(response.responseData.translatedText)")
                    completion(.success(response.responseData.translatedText))
                } catch {
                    print("Error decoding translation response: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
