//
//  GalleryView.swift
//  CameraPlus
//
//  Created by francisco eduardo aramburo reyes on 10/11/25.
//

import SwiftUI
import CoreData

struct GalleryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Obtener todas las fotos, ordenadas de más reciente a más antigua
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EditedPhoto.createdAt, ascending: false)],
        animation: .default
    ) private var photos: FetchedResults<EditedPhoto>
    
    @State private var selectedPhoto: EditedPhoto?
    
    // Grid de 3 columnas
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        Group {
            if photos.isEmpty {
                // Estado vacío
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("No saved photos yet")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Edit and save photos to see them here")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Grid de miniaturas
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(photos) { photo in
                            if let imageData = photo.imageData,
                               let uiImage = UIImage(data: imageData) {
                                
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        selectedPhoto = photo
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}
