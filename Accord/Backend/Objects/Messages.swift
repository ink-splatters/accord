//
//  Messages.swift
//  Accord
//
//  Created by evelyn on 2021-03-07.
//

import Foundation
import SwiftUI

let cache: URLCache? = URLCache.shared

struct ImageWithURL: View, Equatable {
    static func == (lhs: ImageWithURL, rhs: ImageWithURL) -> Bool {
        return true
    }
    
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        HStack {
            Image(nsImage: (NSImage(data: imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0))))
                  .resizable()
                  .clipped()
        }

    }
}

struct Attachment: View, Equatable {
    static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return true
    }
    
    
    @ObservedObject var imageLoader: ImageLoaderAndCache

    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: NSImage(data: imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0)))
              .resizable()
              .scaledToFit()
              .onDisappear {
                  imageLoader.imageData = Data()
              }
    }

}

struct HoveredAttachment: View, Equatable {
    
    static func == (lhs: HoveredAttachment, rhs: HoveredAttachment) -> Bool {
        return true
    }
    
    @ObservedObject var imageLoader: ImageLoaderAndCache
    @State var hovering = false
    
    init(_ url: String) {
        imageLoader = ImageLoaderAndCache(imageURL: url)
    }

    var body: some View {
        Image(nsImage: NSImage(data: imageLoader.imageData) ?? NSImage(size: NSSize(width: 0, height: 0)))
              .resizable()
              .scaledToFit()
              .padding(2)
              .background(hovering ? Color.gray.opacity(0.75).cornerRadius(1) : Color.clear.cornerRadius(0))
              .onDisappear {
                  imageLoader.imageData = Data()
              }
              .onHover(perform: { _ in
                  hovering.toggle()
              })
    }
}

class ImageLoaderAndCache: ObservableObject {
    
    @Published var imageData = Data()
    let imageQueue = DispatchQueue(label: "ImageQueue")

    init(imageURL: String) {
        imageQueue.async { [weak self] in
            let config = URLSessionConfiguration.default
            config.urlCache = cache
            let session = URLSession(configuration: config)
            let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let diskCacheURL = cachesURL.appendingPathComponent("DownloadCache")
            let cache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 1_000_000_000, directory: diskCacheURL)
            if let url = URL(string: imageURL) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 3.0)
                if let data = cache.cachedResponse(for: request)?.data {
                    DispatchQueue.main.async {
                        print("cached")
                        self?.imageData = data
                    }
                } else {
                    session.dataTask(with: request, completionHandler: { (data, response, error) in
                        if let data = data, let response = response {
                        let cachedData = CachedURLResponse(response: response, data: data)
                            cache.storeCachedResponse(cachedData, for: request)
                            DispatchQueue.main.async {
                                print("network")
                                self?.imageData = data
                            }
                        }
                    }).resume()
                }
            }
        }

    }
    
    deinit {
        print("[Accord] unloaded image")
    }
}


func getImage(url: String) -> Data {
    var ret: Data = Data()
    NetworkHandling.shared?.requestData(url: url, token: nil, json: false, type: .GET, bodyObject: [:]) { success, data in
        if (success) {
            ret = data ?? Data()
        }
    }
    return ret
}
