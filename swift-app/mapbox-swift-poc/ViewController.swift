//
//  ViewController.swift
//  mapbox-swift-poc
//
//  Created by Jeremy Bull on 2/24/21.
//

import UIKit
import Mapbox

extension UIButton {
    func setup(title: String, x: CGFloat, y: CGFloat){
        frame = CGRect(x: x, y: y, width: 220, height: 50)
        setTitle(title , for: .normal)
        setTitleColor(.systemBlue, for: .normal)
    }
}

class ViewController: UIViewController {

    let packName = "offline-test-pack";
    let styleURL = URL(string: "http://localhost/styles.json")

    var resetButton: UIButton = UIButton()
    var downloadButton: UIButton = UIButton()
    var peekButton: UIButton = UIButton()
    var deleteButton: UIButton = UIButton()
    var invalidateButton: UIButton = UIButton()
    var resumeButton: UIButton = UIButton()
    var clearAmbientButton: UIButton = UIButton()

    @objc func resetDatabase(sender: UIButton!) throws {
        print("resetDatabase")
    
        MGLOfflineStorage.shared.resetDatabase { (error) in
            guard error == nil else {
                print("Error: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            DispatchQueue.main.async { [unowned self] in
                self.presentCompletionAlertWithContent(title: "Database Reset", message: "The database has been reset")
            }
        }
    }

    @objc func downloadRegion(sender: UIButton!) throws {
        let zoom: Double = 0
        let bounds = MGLCoordinateBounds(
            sw: CLLocationCoordinate2D(latitude: 44.464746, longitude: -73.2158599),
            ne: CLLocationCoordinate2D(latitude: 44.528509, longitude: -73.1499419)
        )

        let region = MGLTilePyramidOfflineRegion(styleURL: styleURL, bounds: bounds, fromZoomLevel: zoom, toZoomLevel: zoom)

        let info = ["name": packName]
        let context = try NSKeyedArchiver.archivedData(withRootObject: info, requiringSecureCoding: false)
        
        MGLOfflineStorage.shared.addPack(for: region, withContext: context) { (pack, error) in
            guard error == nil else {
                print("Error: \(error?.localizedDescription ?? "error creating pack")")
                return
            }
            pack!.resume() // start downloading
        }
    }

    @objc func peekAtDownload(sender: UIButton!) throws {
        print("peeking")
        
        if let packs = MGLOfflineStorage.shared.packs {
            for pack in packs {
                if let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String] {
                    let progress = pack.progress
                    let completedResources = progress.countOfResourcesCompleted
                    let expectedResources = progress.countOfResourcesExpected

                    let progressPercentage = Float(completedResources) / Float(expectedResources)

                    if completedResources == expectedResources {
                        let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                        print("Offline pack “\(userInfo["name"] ?? "unknown")” completed: \(byteCount), \(completedResources) resources")
                    } else {
                        print("Offline pack “\(userInfo["name"] ?? "unknown")” has \(completedResources) of \(expectedResources) resources — \(String(format: "%.2f", progressPercentage * 100))%.")
                    }
                }
            }
        }
    }

    @objc func deleteDownload(sender: UIButton!) throws {
        print("deleting")

        if let pack = MGLOfflineStorage.shared.packs?.first {
            MGLOfflineStorage.shared.removePack(pack) { (error) in
                guard error == nil else {
                    print("Error: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                DispatchQueue.main.async { [unowned self] in
                    self.presentCompletionAlertWithContent(title: "Offline Pack deleted", message: "Deleted offline pack")
                }
            }
        }
    }

    @objc func invalidateDownload(sender: UIButton!) throws {
        print("invalidating")

        if let pack = MGLOfflineStorage.shared.packs?.first {
            MGLOfflineStorage.shared.invalidatePack(pack) { (error) in
                guard error == nil else {
                    print("Error: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                DispatchQueue.main.async { [unowned self] in
                    self.presentCompletionAlertWithContent(title: "Offline Pack Invalidated", message: "Invalidated offline pack")
                }
            }
        }
    }

    @objc func resumeDownload(sender: UIButton!) throws {
        print("resuming")
        
        if let pack = MGLOfflineStorage.shared.packs?.first {
            pack.resume()
            print("resumed")
        }
    }

    @objc func clearAmbient(sender: UIButton!) throws {
        print("clearAmbient")

        MGLOfflineStorage.shared.clearAmbientCache { (error) in
            guard error == nil else {
                print("Error: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            DispatchQueue.main.async { [unowned self] in
                self.presentCompletionAlertWithContent(title: "Cleared Ambient Cache", message: "Ambient cache has been cleared")
            }
        }
    }

    func presentCompletionAlertWithContent(title: String, message: String) {
        let completionController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        completionController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(completionController, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Map
        // let mapView = MGLMapView(frame: view.bounds, styleURL: styleURL)
        // mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // mapView.setCenter(CLLocationCoordinate2D(latitude: 44.496, longitude: -73.182), zoomLevel: 13, animated: false)
        // view.addSubview(mapView)

        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)

        resetButton.setup(title: "Reset", x: 50, y: 50)
        resetButton.addTarget(self, action: #selector(resetDatabase), for: .touchUpInside)
        self.view.addSubview(resetButton)

        downloadButton.setup(title: "Download z0", x: 50, y: 100)
        downloadButton.addTarget(self, action: #selector(downloadRegion), for: .touchUpInside)
        self.view.addSubview(downloadButton)

        peekButton.setup(title: "Peek at Download", x: 50, y: 150)
        peekButton.addTarget(self, action: #selector(peekAtDownload), for: .touchUpInside)
        self.view.addSubview(peekButton)

        deleteButton.setup(title: "Delete", x: 50, y: 200)
        deleteButton.addTarget(self, action: #selector(deleteDownload), for: .touchUpInside)
        self.view.addSubview(deleteButton)

        invalidateButton.setup(title: "Invalidate", x: 50, y: 250)
        invalidateButton.addTarget(self, action: #selector(invalidateDownload), for: .touchUpInside)
        self.view.addSubview(invalidateButton)

        resumeButton.setup(title: "Resume", x: 50, y: 300)
        resumeButton.addTarget(self, action: #selector(resumeDownload), for: .touchUpInside)
        self.view.addSubview(resumeButton)

        clearAmbientButton.setup(title: "Clear Ambient", x: 50, y: 350)
        clearAmbientButton.addTarget(self, action: #selector(clearAmbient), for: .touchUpInside)
        self.view.addSubview(clearAmbientButton)
    }
    
    @objc func offlinePackProgressDidChange(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String] {
            let progress = pack.progress
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected

            let progressPercentage = Float(completedResources) / Float(expectedResources)

            if completedResources == expectedResources {
                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                print("Offline pack “\(userInfo["name"] ?? "unknown")” completed: \(byteCount), \(completedResources) resources")
            } else {
                print("Offline pack “\(userInfo["name"] ?? "unknown")” has \(completedResources) of \(expectedResources) resources — \(String(format: "%.2f", progressPercentage * 100))%.")
            }
        }
    }

    @objc func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
            let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
            print("Offline pack “\(userInfo["name"] ?? "unknown")” received error: \(error.localizedFailureReason ?? "unknown error")")
        }
    }

    @objc func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            let userInfo = NSKeyedUnarchiver.unarchiveObject(with: pack.context) as? [String: String],
            let maximumCount = (notification.userInfo?[MGLOfflinePackUserInfoKey.maximumCount] as AnyObject).uint64Value {
            print("Offline pack “\(userInfo["name"] ?? "unknown")” reached limit of \(maximumCount) tiles.")
        }
    }

}
