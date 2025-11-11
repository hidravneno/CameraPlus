//
//  PhotoDetailView.swift
//  CameraPlus
//
//  Created by francisco eduardo aramburo reyes on 10/11/25.
//

import SwiftUI
import CoreData

struct PhotoDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let photo: EditedPhoto
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Imagen grande
                    if let imageData = photo.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    }
                    
                    // Metadatos
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Filter", systemImage: "camera.filters")
                            Spacer()
                            Text(photo.filter ?? "None")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Label("Intensity", systemImage: "slider.horizontal.3")
                            Spacer()
                            Text(String(format: "%.2f", photo.intensity))
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Label("Date", systemImage: "calendar")
                            Spacer()
                            Text(photo.createdAt ?? Date(), style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        deletePhoto()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    private func deletePhoto() {
        viewContext.delete(photo)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting: \(error)")
        }
    }
}
