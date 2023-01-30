//
//  PhotoView.swift
//  Unsplash
//
//  Created by Olivier Collet on 2017-11-06.
//  Copyright © 2017 Unsplash. All rights reserved.
//

import UIKit

class PhotoView: UIView {

    var authorSelected: AuthorSelectionBlock?

    static var nib: UINib { return UINib(nibName: "PhotoView", bundle: Bundle.local) }

    private var currentPhotoID: String?
    private var imageDownloader = ImageDownloader()
    private var screenScale: CGFloat { return UIScreen.main.scale }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet var userNameButton: UIButton!
    private var photo: UnsplashPhoto?

    var showsUsername = true {
        didSet {
            userNameButton.alpha = showsUsername ? 1 : 0
            gradientView.alpha = showsUsername ? 1 : 0
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        accessibilityIgnoresInvertColors = true
        gradientView.setColors([
            GradientView.Color(color: .clear, location: 0),
            GradientView.Color(color: UIColor(white: 0, alpha: 0.5), location: 1)
        ])
    }

    func prepareForReuse() {
        currentPhotoID = nil
        userNameButton.setAttributedTitle(nil, for: .normal)
        imageView.backgroundColor = .clear
        imageView.image = nil
        photo = nil
        imageDownloader.cancel()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let fontSize: CGFloat = traitCollection.horizontalSizeClass == .compact ? 10 : 13
        updateUsernameButtonTitle(photo?.user.displayName, fontSize: fontSize)
    }

    @IBAction func handleAuthorTap(sender: UIButton) {
        guard let user = photo?.user else { return }
        authorSelected?(user)
    }

    // MARK: - Setup

    func configure(with photo: UnsplashPhoto, showsUsername: Bool = true) {
        self.photo = photo
        self.showsUsername = showsUsername
        imageView.backgroundColor = photo.color
        currentPhotoID = photo.identifier
        downloadImage(with: photo)
        updateUsernameButtonTitle(photo.user.displayName)
    }

    private func updateUsernameButtonTitle(_ title: String?, fontSize: CGFloat = 13) {
        guard let title else {
            userNameButton.setAttributedTitle(nil, for: .normal)
            return
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: UIColor.white
        ]
        let usernameTitle = NSAttributedString(string: title, attributes: attributes)
        userNameButton.setAttributedTitle(usernameTitle, for: .normal)
    }

    private func downloadImage(with photo: UnsplashPhoto) {
        guard let regularUrl = photo.urls[.regular] else { return }

        let url = sizedImageURL(from: regularUrl)

        let downloadPhotoID = photo.identifier

        imageDownloader.downloadPhoto(with: url, completion: { [weak self] (image, isCached) in
            guard let strongSelf = self, strongSelf.currentPhotoID == downloadPhotoID else { return }

            if isCached {
                strongSelf.imageView.image = image
            } else {
                UIView.transition(with: strongSelf, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                    strongSelf.imageView.image = image
                }, completion: nil)
            }
        })
    }

    private func sizedImageURL(from url: URL) -> URL {
        layoutIfNeeded()
        return url.appending(queryItems: [
            URLQueryItem(name: "w", value: "\(frame.width)"),
            URLQueryItem(name: "dpr", value: "\(Int(screenScale))")
        ])
    }

    // MARK: - Utility

    class func view(with photo: UnsplashPhoto) -> PhotoView? {
        guard let photoView = nib.instantiate(withOwner: nil, options: nil).first as? PhotoView else {
            return nil
        }

        photoView.configure(with: photo)

        return photoView
    }

}
