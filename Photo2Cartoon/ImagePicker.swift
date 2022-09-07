//
//  ImagePicker.swift
//  Photo2Cartoon
//
//  Created by sebastiao Gazolla Costa Junior on 06/09/22.
//

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    
    @Binding var image:UIImage
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(imgPicker: self)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
        let imgPicker:ImagePicker
        init(imgPicker:ImagePicker){
            self.imgPicker = imgPicker
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                imgPicker.image = image
            } else {
                // return error
            }
            picker.dismiss(animated: true)
        }
    }
    
   
}

