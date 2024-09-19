import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class NotificationServices {
  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "jainrailwayfooddelivery",
      "private_key_id": "2223804d434eaa7d238c49c6c4285bdbc77f97b6",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCbzTHlGhj4leyF\nlKm54I1s5nyOXhumiczIiy+z5I8KQJjo0acbU/NKbKpPZ729wK9L9mkk2jqwKWaI\naSr5hgWNnwhShjvsXeqfzDrfGOaYHQZur9KoAPbtH+AJDIvFpLepnC47NYyZZK0q\nCIGtBe9qReQ4SCU8Zd7zrcMM4osies5IqMzGahNfb81IrxZPIL5fZstDSBUPJ8BP\nWisCHOn2kIlbh9ERmfzWDCpmFaFYpObY3uNr2wzt8eeraVJ9qVGfcf1pFXwkxuEG\nEv6T5YOqBlUb+pCyP988YetQM06twLHYQEHphnhzNFXjTtEz9HJVfNXM+C7PWcbo\nPRleBJIrAgMBAAECggEAEUPjcBZ8xutiSwlG57TFJ1jBW8t89+8UVPLrpd1Bpqqy\n5zX4dTRP5SL2mpcN9T2pj1rumuleEJB97sbsvrsF2YRSmUaL1G0x52Rr77YkM54f\nzNtKFlkJBA0AuC/+Ozg+LBsFGoWcH5GDCQHpUOGz/sxg9oW0LqXBV7KdR0vBjF/w\nQXqVDsuE46rRll4ZWakRRkbpk9xiqO+wNQoUNKOmPJem7h+LjwsmHKIhI1BbqstO\n+31DPTBjkdFZX2vRc6SnrfMNDSHBGs7wocq5BRAg2uemlaeqKeFz3q5mnF4XnJme\n7VipxvUcAQFkVx5q9WERfehmhZqv+Lx9Wfp2Ocjk5QKBgQDJNrAYyHcfRpThQepi\nEX20DGB05cB7Z2C98gOYR5T2sBH+/KwfBQRgQkOu4IXRxYQQto32gxkOIhoaaJsM\no6+cpAKWNV8NBezbu+9AM2togFlzOE4N+USmQDJtehwVJMH7PyeYcrWreeNAEn7X\nRcJriXe9eWf+bR/Gt4q4L7aThwKBgQDGOR8xv8ihQQhHeZHUzV6xlskUKDLJ/SO6\naYZB1z83mR+KyKkfow65Qq7YtLnPtdmWW2lqc8cP5xN9f9DnRzpKWTnk7kcgDbN+\nt1kQtbSI/9D174JJvXQ1Oe7nbz4xoeiBTUV1tqgWusUh2l+iGH5zwRQmKWW6bHfK\nRvIjjlH9PQKBgD63L/4ZhZ+W9VKco/x7LS4QaYQmFG+iUjICHAK71P9q88EBanik\nrK+AF+6LBsrSgI5hCDCcvhN8p5wxnJo87sCpEjFVY1IA1cnLcxAUtta0oqzaEOIk\nHrSe79jVpaklctzn22SV5HAVJrLS0PwyPx4bk9nX3IUd6Dic/rzYClVDAoGBAITe\n4VQdtESzLPOMP/6fMyxjYKIMWA8higN4nLAhspR4JbaHzyYPzNzOIBnO+waKZTHu\nUHk05mh4go4LUWLWUfJoYPBd8HtB8+Gq0R7sTfnPUKiqRXFcdzr+fG/SF6R5XTrf\nKwI+z+l8hIuur5AeTxUUhYcXFMOj1aBXchP3YGoZAoGAfq0pP3r8DAeZyLqWZLY8\nQALQ7DzulgvJ0MCqV8HPwKnOcDX47EeRdUcvoP2N0fOaEyDhcADgy25/WOUnEUkv\n5d6ifidWO5AU3E4EwGzNnd1kqEueZ1qB3eu7/OO1ayVNUftS4qc9nh1SoFNaVYqD\nix5yF0OrKum3fXwIHWs9F5k=\n-----END PRIVATE KEY-----\n",
      "client_email":
          "notification-service@jainrailwayfooddelivery.iam.gserviceaccount.com",
      "client_id": "118343587765028362599",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/notification-service%40jainrailwayfooddelivery.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);
    client.close();
    return credentials.accessToken.data;
  }

  static Future<void> sendNotificationToSelectedDriver(
      String token, BuildContext context, String title, String? body) async {
    try {
      final String serverKey = await getAccessToken();
      String endpointFirebaseCloudMessaging =
          'https://fcm.googleapis.com/v1/projects/jainrailwayfooddelivery/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body}
        }
      };

      final http.Response response = await http.post(
        Uri.parse(endpointFirebaseCloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print(
            'Failed to send notification. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
