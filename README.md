# KituraBotFacebookMessenger
Swift Kitura Facebook Messenger Webhook

This is a porting on Swift Kitura framework of the Node.js Bot sample described on  Facebook documentation (https://developers.facebook.com/docs/messenger-platform/implementation#subscribe_app_pages)

Setup Facebook Messenger Bot configuration in the Configuration.swift file

Usage:
    
    let _ = KituraBotFacebookMessenger(appSecret: Configuration.appSecret, validationToken: Configuration.validationToken, pageAccessToken: Configuration.pageAccessToken, webHookPath: "/webhook", sendApiPath: "/sendmessage", router: router) { (senderId: String, message: String) -> String? in
        //Implement your BOT logic and return a response message
        let responseMessage = "ECHO: \(message)"

        print("Received message: \(message)")
        print("Response message: \(responseMessage)")
    
        return responseMessage
    
        //return nil //to do not send back any response message
    }


