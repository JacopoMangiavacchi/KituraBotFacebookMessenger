//
//  KituraBotFacebookMessenger
//
//  Created by Jacopo Mangiavacchi on 9/25/16.
//
//


import PackageDescription

let package = Package(
    name: "KituraBotFacebookMessenger",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 0),
        .Package(url: "https://github.com/IBM-Swift/Swift-cfenv.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Bluemix/cf-deployment-tracker-client-swift.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/JacopoMangiavacchi/Kitura-Request.git", majorVersion: 0)
    ])
