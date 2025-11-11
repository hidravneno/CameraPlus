
import SwiftUI
import UIKit
import AVFoundation
import CoreData
struct CameraPlusView: View {
    @Environment(\.managedObjectContext) private var viewContext //access the core data
    
    @State private var showingPicker = false
    @State private var selectedSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?

    @State private var selectedFilter: FilterOption = .noir
    @State private var intensity: Double = 0.7

    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var isComparing: Bool = false
    @State private var showSavedToast: Bool = false

    private let processor = ImageProcessor()
    private let saver = PhotoSaver()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Source selector
                Picker("Source", selection: $selectedSource) {
                    Text("Library").tag(UIImagePickerController.SourceType.photoLibrary)
                    Text("Camera").tag(UIImagePickerController.SourceType.camera)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Image preview card
                Group {
                    if originalImage != nil || processedImage != nil {
                        GeometryReader { geo in
                            ZStack {
                                // ORIGINAL on bottom
                                if let orig = originalImage {
                                    Image(uiImage: orig)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                                        .opacity(isComparing ? 1 : 0)
                                }

                                // PROCESSED on top
                                if let edited = processedImage ?? originalImage {
                                    Image(uiImage: edited)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                                        .opacity(isComparing ? 0 : 1)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            // Ensure the whole card is hittable
                            .contentShape(Rectangle())
                            // Hold-to-compare using pressing callback (no view identity swap)
                            .onLongPressGesture(minimumDuration: 0.01, maximumDistance: .infinity, pressing: { down in
                                isComparing = down
                            }, perform: { })
                            // Corner badge
                            .overlay(
                                Group {
                                    if processedImage != nil {
                                        Text(isComparing ? "Original" : selectedFilter.rawValue)
                                            .font(.caption2)
                                            .padding(6)
                                            .background(.ultraThinMaterial, in: Capsule())
                                            .padding(8)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    }
                                }
                            )
                        }
                    } else {
                        // Placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.06))
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No image selected")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 280)
                .padding(.horizontal)


                // Controls
                VStack(spacing: 12) {
                    HStack {
                        Button(action: pickImage) {
                            Label(selectedSource == .camera ? "Take Photo" : "Choose Photo", systemImage: selectedSource == .camera ? "camera" : "photo")
                        }
                        .buttonStyle(.borderedProminent)

                        Spacer()
                        
                        //button gallery
                        NavigationLink(destination: GalleryView()) {
                            Label("Gallery" , systemImage: "squere.grid.2x2")
                        }

                        Button(action: saveImage) {
                            Label("Save", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .disabled((processedImage ?? originalImage) == nil)
                    }

                    // Filter picker
                    HStack {
                        Text("Filter")
                        Spacer()
                        Menu {
                            Picker("Filter", selection: $selectedFilter) {
                                ForEach(FilterOption.allCases) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                        } label: {
                            Label(selectedFilter.rawValue, systemImage: "slider.horizontal.3")
                        }
                    }

                    // Intensity slider (conditional)
                    if selectedFilter.supportsIntensity {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Intensity")
                                Spacer()
                                Text(String(format: "%.2f", intensity))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $intensity, in: 0...1, step: 0.01) { _ in
                                applyFilter()
                            }
                        }
                    }

                    // Reset / Original toggle
                    HStack {
                        Button(role: .destructive) {
                            originalImage = nil
                            processedImage = nil
                        } label: {
                            Label("Clear", systemImage: "xmark.circle")
                        }
                        .disabled(originalImage == nil && processedImage == nil)

                        Spacer()

                        Button {
                            processedImage = originalImage
                        } label: {
                            Label("Show Original", systemImage: "eye")
                        }
                        .disabled(originalImage == nil)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 8)
            }
            .overlay(
                Group {
                    if showSavedToast {
                        Text("Saved ✓")
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule().stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            )
                            .padding(.bottom, 24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .transition(.opacity)
                    }
                }
            )
            .navigationTitle("Camera Plus")
            .sheet(isPresented: $showingPicker) {
                ImagePicker(isPresented: $showingPicker, image: $originalImage, sourceType: selectedSource, allowsEditing: true)
                    .onDisappear { applyFilter() }
            }
            .alert("Saved", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveMessage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }


    private func pickImage() {
        if selectedSource == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
            errorMessage = "Camera is not available on this device. Switch to Photo Library."
            showError = true
            return
        }

        // Optional preflight camera authorization check for nicer UX
        if selectedSource == .camera {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .denied, .restricted:
                errorMessage = "Camera permission denied. Enable it in Settings > Privacy > Camera."
                showError = true
                return
            case .notDetermined:
                // Let the picker trigger the prompt; we could also proactively request here.
                break
            case .authorized:
                break
            @unknown default:
                break
            }
        }

        showingPicker = true
    }

    private func applyFilter() {
        guard let base = originalImage else { processedImage = nil; return }
        processedImage = processor.apply(filter: selectedFilter, intensity: intensity, to: base)
    }

    private func saveImage() {
        guard let imageToSave = (processedImage ?? originalImage) else { return }
        saver.writeToPhotoAlbum(image: imageToSave) { error in
            if let error {
                saveMessage = "Failed to save: \(error.localizedDescription)"
            } else {
                
                saveToCoreData(image: imageToSave)

                saveMessage = "Image saved to Photos."
                // Haptics + toast
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
                withAnimation { showSavedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation { showSavedToast = false }
                }
            }
            showSaveAlert = true
        }
    }
        private func saveToCoreData(image: UIImage) {
            let item = EditedPhoto(context: viewContext)
            item.id = UUID()
            item.createdAt = Date()
            item.filter = selectedFilter.rawValue
            item.intensity = intensity
            item.imageData = image.jpegData(compressionQuality: 0.9)
            
            do {
                try viewContext.save()
                print("✅ Photo saved in Core Data")
            } catch {
                print("❌ Error saving to Core Data: \(error)")
            }
        }
        
    }

