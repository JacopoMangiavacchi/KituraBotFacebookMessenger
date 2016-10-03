//
//  KituraBotFacebookMessenger.swift
//  KituraBotFacebookMessenger
//
//  Created by Jacopo Mangiavacchi on 9/25/16.
//
//

import Foundation
import SwiftyJSON
import Kitura
import KituraRequest
import LoggerAPI
import KituraBot


// MARK KituraBotFacebookMessenger

/// Implement Facebook Messenger Bot Webhook.
/// See [Facebook's documentation](https://developers.facebook.com/docs/messenger-platform/implementation#subscribe_app_pages)
/// for more information.
public class KituraBotFacebookMessenger : KituraBotProtocol {
    public var channelName: String?
    public var botProtocolMessageNotificationHandler: BotInternalMessageNotificationHandler?

    private let appSecret: String
    private let validationToken: String
    public let pageAccessToken: String
    public let webHookPath: String
    
    /// Initialize a `KituraBotFacebookMessenger` instance.
    ///
    /// - Parameter appSecret: App Secret can be retrieved from the App Dashboard.
    /// - Parameter validationToken: Arbitrary value used to validate a webhook.
    /// - Parameter pageAccessToken: Generate a page access token for your page from the App Dashboard.
    /// - Parameter webHookPath: URI for the webhook.
    public init(appSecret: String, validationToken: String, pageAccessToken: String, webHookPath: String) {
        self.appSecret = appSecret
        self.validationToken = validationToken
        self.pageAccessToken = pageAccessToken
        self.webHookPath = webHookPath
    }
    
    public func configure(router: Router, channelName: String, botProtocolMessageNotificationHandler: @escaping BotInternalMessageNotificationHandler) {
        self.channelName = channelName
        self.botProtocolMessageNotificationHandler = botProtocolMessageNotificationHandler
        
        router.get(webHookPath, handler: validateTokenHandler)
        router.post(webHookPath, handler: processRequestHandler)
    }
    
    //Send a text message using the internal Send API.
    public func sendTextMessage(recipientId: String, messageText: String, context: [String: Any]?) {
        let messageData = ["recipient" : ["id" : recipientId], "message" : ["text" : messageText]]
        
        callSendAPI(messageData: messageData)
    }
    
    
    //PRIVATE REST API Handlers
    
    /// Use your own validation token. Check that the token used in the Webhook
    /// setup is the same token used here.
    private func validateTokenHandler(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.debug("GET - validateToken request")
        print("GET - validateToken request")
        
        guard request.queryParameters["hub.mode"] == "subscribe", request.queryParameters["hub.verify_token"] == validationToken
            else {
                Log.debug("Failed validation. Make sure the validation tokens match.")
                print("Failed validation. Make sure the validation tokens match.")
                
                try response.status(.forbidden).end()  //403
                return
        }
        
        Log.debug("Validating webhook")
        print("Validating webhook")
        try response.status(.OK).send(request.queryParameters["hub.challenge"]!).end()
    }
    
    
    
    /// All callbacks for Messenger are POST-ed. They will be sent to the same
    /// webhook. Be sure to subscribe your app to your page to receive callbacks
    /// for your page.
    /// https://developers.facebook.com/docs/messenger-platform/implementation#subscribe_app_pages
    private func processRequestHandler(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
        Log.debug("POST - process Bot request message")
        print("POST - process Bot request message")
        
        var data = Data()
        if try request.read(into: &data) > 0 {
            let json = JSON(data: data)
            if json["object"] == "page" {
                // Iterate over each entry
                // There may be multiple if batched
                for (_, entry):(String, JSON) in json["entry"] {
                    //var pageID = entry["id"]
                    //var timeOfEvent = entry["time"]
                    
                    // Iterate over each messaging event
                    for (_, message):(String, JSON) in entry["messaging"] {
                        
                        print("Message: \(message)")
                        
                        if message["optin"].exists() {
                            receivedAuthentication(message: message)
                        }
                        else if message["message"].exists() {
                            receivedMessage(message: message)
                        }
                        else if message["delivery"].exists() {
                            receivedDeliveryConfirmation(message: message)
                        }
                        else if message["postback"].exists() {
                            receivedPostback(message: message)
                        }
                        else {
                            Log.debug("Webhook received unknown messagingEvent: \(message)")
                            print("Webhook received unknown messagingEvent: \(message)")
                        }
                    }
                }
            } else {
                Log.debug("Webhook received NO BODY")
                print("Webhook received NO BODY")
            }
        }
        
        try response.status(.OK).end()
    }
    
    
    //PRIVATE Internal Methods for Facebook
    
    
    //Call the Send API. The message data goes in the body. If successful, we'll
    //get the message id in a response
    private func callSendAPI(messageData: [String : [String:String]]) {
        KituraRequest.request(.POST,
                              "https://graph.facebook.com/v2.6/me/messages?access_token=\(pageAccessToken)",
            parameters: messageData,
            encoding: JSONEncoding.default).response({ (_, response, data, error) in
                if let _ = error {
                    Log.debug("Unable to send message.")
                    print("Unable to send message.")
                }
                else {
                    Log.debug("Successfully sent generic message with response: \(response.debugDescription)")
                    print("Successfully sent generic message with response: \(response.debugDescription)")
                }
            })
    }
    
    
    //NOT SUPPORTED YET
    private func sendImageMessage(recipientId: String) {}
    private func sendButtonMessage(recipientId: String) {}
    private func sendGenericMessage(recipientId: String) {}
    private func sendReceiptMessage(recipientId: String) {}
    
    
    //Authorization Event
    //
    //The value for 'optin.ref' is defined in the entry point. For the "Send to
    //Messenger" plugin, it is the 'data-ref' field. Read more at
    //https://developers.facebook.com/docs/messenger-platform/webhook-reference#auth
    private func receivedAuthentication(message: JSON) {
        if let senderID = message["sender"]["id"].string {
            let recipientID = message["recipient"]["id"].string
            let timeOfAuth = message["timestamp"].int
            
            // The 'ref' field is set in the 'Send to Messenger' plugin, in the 'data-ref'
            // The developer can set this to an arbitrary value to associate the
            // authentication callback with the 'Send to Messenger' click event. This is
            // a way to do account linking when the user clicks the 'Send to Messenger'
            // plugin.
            let passThroughParam = message["optin"]["ref"].string
            
            Log.debug("Received authentication for user \(senderID) and page \(recipientID) with pass through param \(passThroughParam) at \(timeOfAuth)")
            print("Received authentication for user \(senderID) and page \(recipientID) with pass through param \(passThroughParam) at \(timeOfAuth)")
            
            // When an authentication is received, we'll send a message back to the sender
            // to let them know it was successful.
            sendTextMessage(recipientId: senderID, messageText: "Authentication successful", context: nil)
        }
        else {
            Log.debug("Unable to get sender id from received authentication.")
            print("Unable to get sender id from received authentication.")
        }
    }
    
    
    //Message Event
    //
    //This event is called when a message is sent to your page. The 'message'
    //object format can vary depending on the kind of message that was received.
    //Read more at https://developers.facebook.com/docs/messenger-platform/webhook-reference#received_message
    //
    //For this example, we're going to echo any text that we get. If we get some
    //special keywords ('button', 'generic', 'receipt'), then we'll send back
    //examples of those bubbles to illustrate the special message bubbles we've
    //created. If we receive a message with an attachment (image, video, audio),
    //then we'll simply confirm that we've received the attachment.
    private func receivedMessage(message: JSON) {
        if let senderID = message["sender"]["id"].string,
            let recipientID = message["recipient"]["id"].string,
            let timeOfMessage = message["timestamp"].int,
            let msgText = message["message"]["text"].string,
            let msgId = message["message"]["mid"].string {
            
            Log.debug("Received message id \(msgId) for user \(senderID) and page \(recipientID) at \(timeOfMessage) with message: \(msgText)")
            print("Received message id \(msgId) for user \(senderID) and page \(recipientID) at \(timeOfMessage) with message: \(msgText)")
            
            // You may get a text or attachment but not both
            if let messageText = message["message"]["text"].string {
                // If we receive a text message, check to see if it matches any special
                // keywords and send back the corresponding example. Otherwise, just echo
                // the text we received.
                switch messageText {
                case "image":
                    sendImageMessage(recipientId: senderID)
                case "button":
                    sendButtonMessage(recipientId: senderID)
                case "generic":
                    sendGenericMessage(recipientId: senderID)
                case "receipt":
                    sendReceiptMessage(recipientId: senderID)
                default:
                    //No Context from Facebook Messenger webhook channel
                    if let (responseMessage, _) = botProtocolMessageNotificationHandler?(channelName!, senderID, msgText, nil) {
                        sendTextMessage(recipientId: senderID, messageText: responseMessage, context: nil)
                    }
                }
            }
            else if let _ = message["message"]["attachments"].string {
                sendTextMessage(recipientId: senderID, messageText: "Message with attachment received", context: nil)
            }
            else {
                sendTextMessage(recipientId: senderID, messageText: "Message unexpected received", context: nil)
                
                Log.debug("Received a message with neither text or attachment")
                print("Received a message with neither text or attachment")
            }
        }
        else {
            Log.debug("Unable to get sender id from received message.")
            print("Unable to get sender id from received message.")
        }
    }
    
    
    //NOT SUPPORTED YET
    private func receivedDeliveryConfirmation(message: JSON) {}
    private func receivedPostback(message: JSON) {}
}


